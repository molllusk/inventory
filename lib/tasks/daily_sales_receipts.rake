namespace :daily_sales_receipts do
  task :pull, [:days_ago] => [:environment] do |task, args|
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    days_ago = args[:days_ago].blank? ? 1 : args[:days_ago].to_i
    day = days_ago.days.ago

    min_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day

    puts "Getting orders from #{days_ago} day(s) ago #{min_date.strftime("%m/%d/%Y")}..."

    orders = ShopifyClient.closed_orders_since(day)
    expected_order_count = ShopifyClient.closed_orders_since_count(day)

    Airbrake.notify("Expected #{expected_order_count} orders, but got #{orders.count} while running daily financial reports") unless orders.count == expected_order_count

    shopify_sales_receipt = Hash.new(0)
    costs_report = Hash.new(0)
    refunded_amounts = Hash.new(0)

    refunded_amounts[:date] = min_date
    shopify_sales_receipt[:date] = min_date
    costs_report[:date] = min_date

    refunds = []

    location_sales_costs = Hash.new(0)
    refund_costs_by_location = Hash.new(0)
        
    order_names_by_id = {}

    sales_totals_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    refund_totals_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    costs_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    orders.each do |order|
      order_names_by_id[order['id']] = order['name']
      costs_by_location = Hash.new(0)

      if %w(refunded partially_refunded).include?(order['financial_status'])
        ShopifyClient.refunds(order['id']).each do |refund|
          next if Time.parse(refund['created_at']) < min_date || Time.parse(refund['created_at']) > max_date
          refunds << refund
        end
      end

      next if Time.parse(order['closed_at']) < min_date || Time.parse(order['closed_at']) > max_date
      order_name = order['name']
      order_tax = order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      sales_totals_by_order[order_name][:order_id] = order['id']
      sales_totals_by_order[order_name][:closed_at] = order['closed_at']
      sales_totals_by_order[order_name][:sales_tax] = order_tax
      sales_totals_by_order[order_name][:discount] = order['total_discounts'].to_f

      shopify_sales_receipt[:discount] += order['total_discounts'].to_f
      shopify_sales_receipt[:sales_tax] += order_tax

      fulfillments = ShopifyClient.fulfillments(order['id'])

      order['line_items'].each do |line_item|
        variant_id = line_item['variant_id']
        fulfillment = fulfillments.detect { |fulfillment| fulfillment['line_items'].detect { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)

        if shopify_product.present?
          cost = shopify_product.get_cost_from_vend * line_item['quantity'].to_f
          costs_by_order[order_name][:cost] += cost
          costs_report[:cost] += cost
          costs_by_location[location_id] += cost
          location_sales_costs[location_id] += cost
        else
          Airbrake.notify("Item sold but missing from app as shopify product by variant id: { variant_id: #{variant_id}, product_id: #{line_item['product_id']} }")
        end

        if line_item['gift_card'] || line_item['product_id'] == 1045344714837 # mollusk money
          shopify_sales_receipt[:gift_card_sales] += line_item['price'].to_f * line_item['quantity'].to_f
          sales_totals_by_order[order_name][:gift_card_sales] += line_item['price'].to_f * line_item['quantity'].to_f
        else
          shopify_sales_receipt[:product_sales] += line_item['price'].to_f * line_item['quantity'].to_f
          sales_totals_by_order[order_name][:product_sales] += line_item['price'].to_f * line_item['quantity'].to_f
        end
      end

      costs_by_order[order_name][:order_id] = order['id']
      costs_by_order[order_name][:closed_at] = order['closed_at']
      costs_by_order[order_name][:location_costs] = costs_by_location

      order_shipping = order['shipping_lines'].reduce(0) { |sum, shipping_line| sum + shipping_line['price'].to_f }

      sales_totals_by_order[order_name][:shipping] = order_shipping
      shopify_sales_receipt[:shipping] += order_shipping

      transactions = ShopifyClient.transactions(order['id'])

      transactions.each do |transaction|
        next unless %w(capture sale refund).include?(transaction['kind']) && transaction['status'] == 'success'

        if %w(capture sale).include?(transaction['kind'])
          case transaction['gateway']
          when 'gift_card'
            sales_totals_by_order[order_name][:gift_card_payments] += transaction['amount'].to_f
            shopify_sales_receipt[:gift_card_payments] += transaction['amount'].to_f
          when 'paypal'
            sales_totals_by_order[order_name][:paypal_payments] += transaction['amount'].to_f
            shopify_sales_receipt[:paypal_payments] += transaction['amount'].to_f
          when 'shopify_payments'
            sales_totals_by_order[order_name][:shopify_payments] += transaction['amount'].to_f
            shopify_sales_receipt[:shopify_payments] += transaction['amount'].to_f
          end
        elsif transaction['kind'] == 'refund' && transaction['gateway'] == 'gift_card'
          if transaction['message'] == 'Another transaction failed so the gift card was rolled back'
            sales_totals_by_order[order_name][:gift_card_payments] -= transaction['amount'].to_f
            shopify_sales_receipt[:gift_card_payments] -= transaction['amount'].to_f
          end
        end
      end
    end

    refunds.each do |refund|
      order_name = order_names_by_id[refund['order_id']]
      fulfillments = ShopifyClient.fulfillments(refund['order_id'])
      costs_by_location = Hash.new(0)

      refund['refund_line_items'].each do |line_item|
        variant_id = line_item['line_item']['variant_id']
        fulfillment = fulfillments.detect { |fulfillment| fulfillment['line_items'].detect { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)

        if shopify_product.present?
          refund_cost = shopify_product.get_cost_from_vend * line_item['quantity'].to_f
          refund_totals_by_order[order_name][:cost] += refund_cost
          refunded_amounts[:cost] += refund_cost
          costs_by_location[location_id] += refund_cost
          refund_costs_by_location[location_id] += refund_cost
        else
          Airbrake.notify("Item Refunded but missing from app as shopify product by variant id: { product_id: #{line_item['line_item']['product_id']}, variant_id: #{variant_id} }")
        end

        refund_discounts = line_item['line_item']['discount_allocations'].reduce(0) { |sum, discount_allocation| sum + discount_allocation['amount'].to_f }
        sub_total = line_item['line_item']['price'].to_f * line_item['quantity'].to_f

        refund_totals_by_order[order_name][:product_sales] += sub_total
        refund_totals_by_order[order_name][:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refund_totals_by_order[order_name][:discount] += refund_discounts
        refunded_amounts[:product_sales] += sub_total
        refunded_amounts[:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refunded_amounts[:discount] += refund_discounts
      end

      refunded_shipping = refund['order_adjustments'].reduce(0) { |sum, adjustment| adjustment['kind'] == 'shipping_refund' ? sum + adjustment['amount'].to_f : sum } * -1
      refunded_amounts[:refunded_shipping] += refunded_shipping

      refund_totals_by_order[order_name][:refunded_shipping] = refunded_shipping
      refund_totals_by_order[order_name][:created_at] = refund['created_at']
      refund_totals_by_order[order_name][:order_id] = refund['order_id']
      refund_totals_by_order[order_name][:location_costs] = costs_by_location

      refund['transactions'].each do |transaction|
        next unless transaction['kind'] == 'refund' && transaction['status'] == 'success'

        case transaction['gateway']
        when 'gift_card'
          refund_totals_by_order[order_name][:gift_card_payments] += transaction['amount'].to_f
          refunded_amounts[:gift_card_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        when 'paypal'
          refund_totals_by_order[order_name][:paypal_payments] += transaction['amount'].to_f
          refunded_amounts[:paypal_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        when 'shopify_payments'
          refund_totals_by_order[order_name][:shopify_payments] += transaction['amount'].to_f
          refunded_amounts[:shopify_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        end
      end
    end

    refunded_amounts[:shipping] = refunded_amounts[:product_sales] + refunded_amounts[:sales_tax] + refunded_amounts[:refunded_shipping] - refunded_amounts[:discount] - refunded_amounts[:total_payments]

    refunded_amounts[:location_costs] = refund_costs_by_location
    costs_report[:location_costs] = location_sales_costs
    
    shopify_sales_cost = ShopifySalesCost.create(costs_report)
    shopify_refund = ShopifyRefund.create(refunded_amounts)
    shopify_sales_receipt = ShopifySalesReceipt.create(shopify_sales_receipt)

    sales_totals_by_order.each do |order_name, values|
      values[:name] = order_name
      shopify_sales_receipt.shopify_sales_receipt_orders << ShopifySalesReceiptOrder.create(values)
    end

    refund_totals_by_order.each do |order_name, values|
      values[:name] = order_name
      values[:shipping] = values[:product_sales] + values[:sales_tax] + values[:refunded_shipping] - values[:discount] - values[:total_payments]
      shopify_refund.shopify_refund_orders << ShopifyRefundOrder.create(values)
    end

    costs_by_order.each do |order_name, values|
      values[:name] = order_name
      shopify_sales_cost.shopify_sales_cost_orders << ShopifySalesCostOrder.create(values)
    end
  end
end

namespace :daily_sales_receipts do
  task :pull, [:days_ago] => [:environment] do |task, args|
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    days_ago = args[:days_ago].blank? ? 1 : args[:days_ago].to_i
    day = days_ago.days.ago

    min_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    min_date -= min_date.utc_offset

    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day
    max_date -= max_date.utc_offset

    puts "Getting orders from #{days_ago} day(s) ago #{min_date.strftime("%m/%d/%Y")}..."

    orders = ShopifyClient.closed_orders_since(day)

    product_sales = 0.0
    discount = 0.0
    gift_card_sales = 0.0
    sales_tax = 0.0
    shipping = 0.0
    shopify_payments = 0.0
    paypal_payments = 0.0
    gift_card_payments = 0.0
    subtotal_price = 0.0
    total_tax = 0.0
    sales_costs = 0.0

    refunds = []
    refund_order_names = []
    order_names = []

    location_sales_costs = Hash.new(0)

    orders.each do |order|
      if %w(refunded partially_refunded).include?(order['financial_status'])
        ShopifyClient.refunds(order['id']).each do |refund|
          next if Time.parse(refund['created_at']) < min_date || Time.parse(refund['created_at']) > max_date
          refund_order_names << order['name']    
          refunds << refund
        end
      end

      next if Time.parse(order['closed_at']) < min_date || Time.parse(order['closed_at']) > max_date
      order_names << order['name']

      subtotal_price += order['subtotal_price'].to_f
      total_tax += order['total_tax'].to_f
      discount += order['total_discounts'].to_f
      sales_tax += order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      fulfillments = ShopifyClient.fulfillments(order['id'])

      order['line_items'].each do |line_item|
        variant_id = line_item['variant_id']
        fulfillment = fulfillments.detect { |fulfillment| fulfillment['line_items'].detect { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)

        if shopify_product.present?
          cost = shopify_product.get_cost_from_vend * line_item['quantity'].to_f
          sales_costs += cost
          location_sales_costs[location_id] += cost
        else
          Airbrake.notify("Item sold but missing from app as shopify product by variant id: { variant_id: #{variant_id}, product_id: #{line_item['product_id']} }")
        end

        if line_item['gift_card'] || line_item['product_id'] == 1045344714837 # mollusk money
          gift_card_sales += line_item['price'].to_f * line_item['quantity'].to_f
        else
          product_sales += line_item['price'].to_f * line_item['quantity'].to_f
        end
      end

      shipping += order['shipping_lines'].reduce(0) { |sum, shipping_line| sum + shipping_line['price'].to_f }

      transactions = ShopifyClient.transactions(order['id'])

      transactions.each do |transaction|
        next unless %w(capture sale).include?(transaction['kind']) && transaction['status'] == 'success'

        case transaction['gateway']
        when 'gift_card'
          gift_card_payments += transaction['amount'].to_f
        when 'paypal'
          paypal_payments += transaction['amount'].to_f
        when 'shopify_payments'
          shopify_payments += transaction['amount'].to_f
        end
      end
    end

    refunded_amounts = Hash.new(0)
    refund_costs_by_location = Hash.new(0)

    refunds.each do |refund|
      fulfillments = ShopifyClient.fulfillments(refund['order_id'])

      refund['refund_line_items'].each do |line_item|
        variant_id = line_item['line_item']['variant_id']
        fulfillment = fulfillments.detect { |fulfillment| fulfillment['line_items'].detect { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)

        if shopify_product.present?
          refund_cost = shopify_product.get_cost_from_vend * line_item['quantity'].to_f
          refunded_amounts[:cost] += refund_cost
          refund_costs_by_location[location_id] += refund_cost
        else
          Airbrake.notify("Item Refunded but missing from app as shopify product by variant id: { product_id: #{line_item['line_item']['product_id']}, variant_id: #{variant_id} }")
        end

        refund_discounts = line_item['line_item']['discount_allocations'].reduce(0) { |sum, discount_allocation| sum + discount_allocation['amount'].to_f }
        sub_total = line_item['line_item']['price'].to_f * line_item['quantity'].to_f

        refunded_amounts[:product_sales] += sub_total
        refunded_amounts[:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refunded_amounts[:discount] += refund_discounts
      end

      refund['transactions'].each do |transaction|
        next unless transaction['kind'] == 'refund' && transaction['status'] == 'success'

        case transaction['gateway']
        when 'gift_card'
          refunded_amounts[:gift_card_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        when 'paypal'
          refunded_amounts[:paypal_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        when 'shopify_payments'
          refunded_amounts[:shopify_payments] += transaction['amount'].to_f
          refunded_amounts[:total_payments] += transaction['amount'].to_f
        end
      end
    end

    refunded_amounts[:shipping] = refunded_amounts[:product_sales] + refunded_amounts[:sales_tax] - refunded_amounts[:discount] - refunded_amounts[:total_payments]
    refunded_amounts[:location_costs] = refund_costs_by_location
    refunded_amounts[:date] = day.beginning_of_day
    
    costs_report = { cost: sales_costs, location_costs: location_sales_costs, date: day.beginning_of_day} 

    ShopifySalesCost.create(costs_report)
    ShopifyRefund.create(refunded_amounts)

    # puts "costs report"
    # p costs_report

    # puts "Refunded Amounts"
    # p refunded_amounts

    # p order_names
    # p refund_order_names

    ShopifySalesReceipt.create(
        date: day.beginning_of_day,
        product_sales: product_sales,
        discount: discount,
        gift_card_sales: gift_card_sales,
        shipping: shipping,
        sales_tax: sales_tax,
        shopify_payments: shopify_payments,
        paypal_payments: paypal_payments,
        gift_card_payments: gift_card_payments
      )

  end
end

# frozen_string_literal: true

class DailySalesReceipts
  include Sidekiq::Worker
  sidekiq_options queue: :accounting, retry: false

  def perform(days_ago = 1)
    day = days_ago.days.ago

    min_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day

    puts "Getting orders from #{days_ago} day(s) ago #{min_date.strftime('%m/%d/%Y')}..."

    orders = ShopifyClient.closed_orders_since(day)
    expected_order_count = ShopifyClient.closed_orders_since_count(day)

    Airbrake.notify("Expected #{expected_order_count} orders, but got #{orders.count} while running daily reports") unless orders.count == expected_order_count

    web_sales = []
    pos_sales = []
    wholesale_orders = []
    refunds = []

    order_names_by_id = {}

    # Filter and sort orders into buckets: web, pos, wholesale, refund
    orders.each do |order|
      # skip internal orders to the shops
      next if order['source_name'] == 'mollusk_app'
      next if order['gateway'] == 'exchange-credit'

      order_names_by_id[order['id']] = order['name']

      is_pos = order['source_name'] == 'pos'
      is_wholesale = order['customer']&.[]('tags')&.include?('wholesale')
      is_refund = %w[refunded partially_refunded].include?(order['financial_status'])

      if is_refund
        ShopifyClient.refunds(order['id']).each do |refund|
          next if Time.parse(refund['created_at']) < min_date || Time.parse(refund['created_at']) > max_date

          refunds << refund
        end
      end

      # out of bounds for sales/cost accounting
      next if Time.parse(order['closed_at']) < min_date || Time.parse(order['closed_at']) > max_date

      # put the order in the right bucket
      if is_wholesale
        wholesale_orders << order
      elsif is_pos
        pos_sales << order
      else
        web_sales << order
      end
    end

    ###########################
    ##### SHOPIFY Website #####
    ###########################

    shopify_sales_receipt = Hash.new(0)
    shopify_sales_receipt[:date] = min_date

    costs_report = Hash.new(0)
    costs_report[:date] = min_date

    sales_totals_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    costs_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    location_sales_costs = Hash.new(0)

    web_sales.each do |order|
      costs_by_location = Hash.new(0)
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
        next unless line_item['fulfillment_status'].present?

        variant_id = line_item['variant_id']
        fulfillment = fulfillments.find { |fulfillment_candidate| fulfillment_candidate['line_items'].find { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        cost = 0.0
        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)
        raw_cost = shopify_product.present? ? shopify_product.get_cost : ShopifyClient.get_cost(variant_id)

        if raw_cost.present?
          cost = raw_cost * line_item['quantity'].to_f
        else
          Airbrake.notify("RETAIL Item sold is missing COST in both systems { order_name: #{order_name}, variant_id: #{variant_id}, product_id: #{line_item['product_id']} }")
        end

        costs_by_order[order_name][:cost] += cost
        costs_report[:cost] += cost
        costs_by_location[location_id] += cost
        location_sales_costs[location_id] += cost

        if line_item['gift_card'] || line_item['product_id'] == 1_045_344_714_837 # mollusk money
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
        next unless %w[capture sale refund].include?(transaction['kind']) && transaction['status'] == 'success'

        if %w[capture sale].include?(transaction['kind'])
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

    ###########################
    ##### SHOPIFY Refunds #####
    ###########################

    refund_costs_by_location = Hash.new(0)
    refund_totals_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    refund_totals_by_pos_location = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    refunded_amounts = Hash.new(0)
    refunded_amounts[:date] = min_date

    refunds.each do |refund|
      order_name = order_names_by_id[refund['order_id']]
      fulfillments = ShopifyClient.fulfillments(refund['order_id'])
      is_pos_refund = refund['source_name'] == 'pos'
      location_id = nil

      costs_by_location = Hash.new(0)

      refund_line_items = refund['refund_line_items']

      refund_line_items.each do |line_item|
        variant_id = line_item['line_item']['variant_id']

        if is_pos_refund
          location_id ||= line_item['location_id']
          refund_totals_by_order[order_name][:pos_location_id] ||= location_id
        else
          fulfillment = fulfillments.find { |fulfillment_candidate| fulfillment_candidate['line_items'].find { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
          location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'
        end

        refund_cost = 0.0
        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)
        raw_cost = shopify_product.present? ? shopify_product.get_cost : ShopifyClient.get_cost(variant_id)

        if raw_cost.present?
          refund_cost = raw_cost * line_item['quantity'].to_f
        else
          Airbrake.notify("Refund missing COST in both systems variant id: { product_id: #{line_item['line_item']['product_id']}, variant_id: #{variant_id} }")
        end

        refund_totals_by_order[order_name][:cost] += refund_cost

        if is_pos_refund
          refund_totals_by_pos_location[location_id][:cost] += refund_cost
        else
          refunded_amounts[:cost] += refund_cost
        end

        costs_by_location[location_id] += refund_cost
        refund_costs_by_location[location_id] += refund_cost

        purchased_quantity = line_item['line_item']['quantity'].to_f
        returned_quantity = line_item['quantity'].to_f

        refund_discounts = line_item['line_item']['discount_allocations'].reduce(0) { |sum, discount_allocation| sum + (discount_allocation['amount'].to_f * (returned_quantity / purchased_quantity)) }
        sub_total = line_item['line_item']['price'].to_f * returned_quantity

        refund_totals_by_order[order_name][:product_sales] += sub_total
        refund_totals_by_order[order_name][:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refund_totals_by_order[order_name][:discount] += refund_discounts

        if is_pos_refund
          refund_totals_by_pos_location[location_id][:product_sales] += sub_total
          refund_totals_by_pos_location[location_id][:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
          refund_totals_by_pos_location[location_id][:discount] += refund_discounts
        else
          refunded_amounts[:product_sales] += sub_total
          refunded_amounts[:sales_tax] += line_item['total_tax'].to_f # or do we want tax lines total
          refunded_amounts[:discount] += refund_discounts
        end
      end

      refunded_shipping = 0
      arbitrary_discount_from_order_adjustments = 0

      # Check order adjustments for adjustments that aren't related to line items
      # If order adjustment is positive is a shipping charge account for elsewhere and we ignore
      refund['order_adjustments'].each do |adjustment|
        if adjustment['kind'] == 'shipping_refund'
          refunded_shipping -= adjustment['amount'].to_f
        elsif adjustment['amount'].to_f.negative?
          arbitrary_discount_from_order_adjustments -= adjustment['amount'].to_f
        end
      end

      refund_totals_by_order[order_name][:refunded_shipping] = refunded_shipping
      refund_totals_by_order[order_name][:arbitrary_discount] = arbitrary_discount_from_order_adjustments

      if is_pos_refund
        refund_totals_by_pos_location[location_id][:refunded_shipping] += refunded_shipping
        refund_totals_by_pos_location[location_id][:arbitrary_discount] += arbitrary_discount_from_order_adjustments
      else
        refunded_amounts[:refunded_shipping] += refunded_shipping
        refunded_amounts[:arbitrary_discount] += arbitrary_discount_from_order_adjustments
      end

      refund_totals_by_order[order_name][:created_at] = refund['created_at']
      refund_totals_by_order[order_name][:order_id] = refund['order_id']
      refund_totals_by_order[order_name][:location_costs] = costs_by_location

      refund['transactions'].each do |transaction|
        next unless transaction['kind'] == 'refund' && transaction['status'] == 'success'

        case transaction['gateway']
        when 'gift_card'
          refund_totals_by_order[order_name][:gift_card_payments] += transaction['amount'].to_f
          refund_totals_by_order[order_name][:total_payments] += transaction['amount'].to_f
          if is_pos_refund
            refund_totals_by_pos_location[location_id][:gift_card_payments] += transaction['amount'].to_f
            refund_totals_by_pos_location[location_id][:total_payments] += transaction['amount'].to_f
          else
            refunded_amounts[:gift_card_payments] += transaction['amount'].to_f
            refunded_amounts[:total_payments] += transaction['amount'].to_f
          end
        when 'paypal'
          refund_totals_by_order[order_name][:paypal_payments] += transaction['amount'].to_f
          refund_totals_by_order[order_name][:total_payments] += transaction['amount'].to_f

          if is_pos_refund
            refund_totals_by_pos_location[location_id][:paypal_payments] += transaction['amount'].to_f
            refund_totals_by_pos_location[location_id][:total_payments] += transaction['amount'].to_f
          else
            refunded_amounts[:paypal_payments] += transaction['amount'].to_f
            refunded_amounts[:total_payments] += transaction['amount'].to_f
          end
        when 'shopify_payments'
          refund_totals_by_order[order_name][:shopify_payments] += transaction['amount'].to_f
          refund_totals_by_order[order_name][:total_payments] += transaction['amount'].to_f

          if is_pos_refund
            refund_totals_by_pos_location[location_id][:shopify_payments] += transaction['amount'].to_f
            refund_totals_by_pos_location[location_id][:total_payments] += transaction['amount'].to_f
          else
            refunded_amounts[:shopify_payments] += transaction['amount'].to_f
            refunded_amounts[:total_payments] += transaction['amount'].to_f
          end
        when 'cash' # POS only
          refund_totals_by_order[order_name][:cash_payments] += transaction['amount'].to_f
          refund_totals_by_order[order_name][:total_payments] += transaction['amount'].to_f

          refund_totals_by_pos_location[location_id][:cash_payments] += transaction['amount'].to_f
          refund_totals_by_pos_location[location_id][:total_payments] += transaction['amount'].to_f
        end
      end

      next unless refund_line_items.blank?

      refund_totals_by_order[order_name][:arbitrary_discount] += (refund_totals_by_order[order_name][:total_payments] - refunded_shipping - arbitrary_discount_from_order_adjustments)

      if is_pos_refund
        refund_totals_by_pos_location[location_id][:arbitrary_discount] += (refund_totals_by_pos_location[order_name][:total_payments] - refunded_shipping - arbitrary_discount_from_order_adjustments)
      else
        refunded_amounts[:arbitrary_discount] += (refund_totals_by_order[order_name][:total_payments] - refunded_shipping - arbitrary_discount_from_order_adjustments)
      end
    end

    ###########################
    #### SHOPIFY WHOLESALE ####
    ###########################

    wholesale_shopify_sales_receipt = Hash.new(0)
    wholesale_costs_report = Hash.new(0)

    wholesale_shopify_sales_receipt[:date] = min_date
    wholesale_costs_report[:date] = min_date

    wholesale_location_sales_costs = Hash.new(0)
    wholesale_sales_totals_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    wholesale_costs_by_order = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    wholesale_orders.each do |order|
      costs_by_location = Hash.new(0)

      order_name = order['name']
      order_tax = order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      wholesale_sales_totals_by_order[order_name][:order_id] = order['id']
      wholesale_sales_totals_by_order[order_name][:closed_at] = order['closed_at']
      wholesale_sales_totals_by_order[order_name][:sales_tax] = order_tax
      wholesale_sales_totals_by_order[order_name][:discount] = order['total_discounts'].to_f

      wholesale_shopify_sales_receipt[:discount] += order['total_discounts'].to_f
      wholesale_shopify_sales_receipt[:sales_tax] += order_tax

      fulfillments = ShopifyClient.fulfillments(order['id'])

      order['line_items'].each do |line_item|
        next unless line_item['fulfillment_status'].present?

        variant_id = line_item['variant_id']
        fulfillment = fulfillments.find { |fulfillment_candidate| fulfillment_candidate['line_items'].find { |fulfillment_line_item| fulfillment_line_item['variant_id'] == variant_id } }
        location_id = fulfillment.present? && fulfillment['location_id'].present? ? fulfillment['location_id'] : 'no_location'

        cost = 0.0
        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)
        raw_cost = shopify_product.present? ? shopify_product.get_cost : ShopifyClient.get_cost(variant_id)

        if raw_cost.present?
          cost = raw_cost * line_item['quantity'].to_f
        else
          Airbrake.notify("WHOLESALE Item sold is missing COST in both systems { order_name: #{order_name}, variant_id: #{variant_id}, product_id: #{line_item['product_id']} }")
        end

        wholesale_costs_by_order[order_name][:cost] += cost
        wholesale_costs_report[:cost] += cost
        costs_by_location[location_id] += cost
        wholesale_location_sales_costs[location_id] += cost

        if line_item['gift_card'] || line_item['product_id'] == 1_045_344_714_837 # mollusk money
          wholesale_shopify_sales_receipt[:gift_card_sales] += line_item['price'].to_f * line_item['quantity'].to_f
          wholesale_sales_totals_by_order[order_name][:gift_card_sales] += line_item['price'].to_f * line_item['quantity'].to_f
        else
          wholesale_shopify_sales_receipt[:product_sales] += line_item['price'].to_f * line_item['quantity'].to_f
          wholesale_sales_totals_by_order[order_name][:product_sales] += line_item['price'].to_f * line_item['quantity'].to_f
        end
      end

      wholesale_costs_by_order[order_name][:order_id] = order['id']
      wholesale_costs_by_order[order_name][:closed_at] = order['closed_at']
      wholesale_costs_by_order[order_name][:location_costs] = costs_by_location

      order_shipping = order['shipping_lines'].reduce(0) { |sum, shipping_line| sum + shipping_line['price'].to_f }

      wholesale_sales_totals_by_order[order_name][:shipping] = order_shipping
      wholesale_shopify_sales_receipt[:shipping] += order_shipping

      transactions = ShopifyClient.transactions(order['id'])

      transactions.each do |transaction|
        next unless %w[capture sale refund].include?(transaction['kind']) && transaction['status'] == 'success'

        if %w[capture sale].include?(transaction['kind'])
          case transaction['gateway']
          when 'gift_card'
            wholesale_sales_totals_by_order[order_name][:gift_card_payments] += transaction['amount'].to_f
            wholesale_shopify_sales_receipt[:gift_card_payments] += transaction['amount'].to_f
          when 'paypal'
            wholesale_sales_totals_by_order[order_name][:paypal_payments] += transaction['amount'].to_f
            wholesale_shopify_sales_receipt[:paypal_payments] += transaction['amount'].to_f
          when 'shopify_payments'
            wholesale_sales_totals_by_order[order_name][:shopify_payments] += transaction['amount'].to_f
            wholesale_shopify_sales_receipt[:shopify_payments] += transaction['amount'].to_f
          end
        elsif transaction['kind'] == 'refund' && transaction['gateway'] == 'gift_card'
          if transaction['message'] == 'Another transaction failed so the gift card was rolled back'
            wholesale_sales_totals_by_order[order_name][:gift_card_payments] -= transaction['amount'].to_f
            wholesale_shopify_sales_receipt[:gift_card_payments] -= transaction['amount'].to_f
          end
        end
      end
    end

    #######################
    #### SHOPIFY Store ####
    #######################

    shopify_pos_sales_receipt = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    shopify_pos_sales_receipt_by_sale = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    shopify_pos_sales_costs = Hash.new { |hash, key| hash[key] = Hash.new(0) }
    shopify_pos_sales_costs_by_sale = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    pos_sales.each do |order|
      location = order['location_id']
      order_name = order['name']
      order_tax = order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      shopify_pos_sales_receipt_by_sale[order_name][:order_id] = order['id']
      shopify_pos_sales_costs_by_sale[order_name][:order_id] = order['id']

      shopify_pos_sales_receipt_by_sale[order_name][:name] = order_name
      shopify_pos_sales_costs_by_sale[order_name][:name] = order_name

      shopify_pos_sales_receipt_by_sale[order_name][:sale_at] = order['closed_at']
      shopify_pos_sales_costs_by_sale[order_name][:sale_at] = order['closed_at']

      shopify_pos_sales_receipt_by_sale[order_name][:location] = location
      shopify_pos_sales_costs_by_sale[order_name][:location] = location

      shopify_pos_sales_receipt[location][:sales_tax] += order_tax
      shopify_pos_sales_receipt_by_sale[order_name][:sales_tax] = order_tax

      shopify_pos_sales_receipt[location][:discount] += order['total_discounts'].to_f
      shopify_pos_sales_receipt_by_sale[order_name][:discount] = order['total_discounts'].to_f

      order['line_items'].each do |line_item|
        next unless line_item['fulfillment_status'].present?

        variant_id = line_item['variant_id']

        cost = 0.0
        shopify_product = ShopifyDatum.find_by(variant_id: variant_id)
        if shopify_product.blank?
          shopify_product = ShopifyClient.get_product(line_item['product_id'])
          product_type = shopify_product['product_type']
          raw_cost = ShopifyClient.get_cost(variant_id)
        else
          product_type = shopify_product.product_type
          raw_cost = shopify_product.get_cost
        end

        if raw_cost.present?
          cost = raw_cost * line_item['quantity'].to_f
        else
          Airbrake.notify("Product sold is missing COST { order_name: #{order_name}, variant_id: #{variant_id}, product_id: #{line_item['product_id']} }")
        end

        shopify_pos_sales_costs[location][:cost] += cost
        shopify_pos_sales_costs_by_sale[order_name][:cost] += cost

        item_total = line_item['price'].to_f * line_item['quantity'].to_f

        case product_type
        when 'Gift Card' # Gift Cards
          shopify_pos_sales_receipt[location][:gift_card_sales] += item_total
          shopify_pos_sales_receipt_by_sale[order_name][:gift_card_sales] += item_total
        when 'Shipping' # Shipping
          shopify_pos_sales_receipt[location][:shipping] += item_total
          shopify_pos_sales_receipt_by_sale[order_name][:shipping] += item_total
        else
          shopify_pos_sales_receipt[location][:product_sales] += item_total
          shopify_pos_sales_receipt_by_sale[order_name][:product_sales] += item_total

          shopify_pos_sales_receipt_by_sale[order_name][:rentals] += item_total if product_type == 'Rental'
        end
      end

      transactions = ShopifyClient.transactions(order['id'])

      transactions.each do |transaction|
        next unless %w[capture sale refund].include?(transaction['kind']) && transaction['status'] == 'success'

        if %w[capture sale].include?(transaction['kind'])
          case transaction['gateway']
          when 'cash'
            shopify_pos_sales_receipt[location][:cash_payments] += transaction['amount'].to_f
            shopify_pos_sales_receipt_by_sale[order_name][:cash_payments] += transaction['amount'].to_f
          when 'gift_card'
            shopify_pos_sales_receipt[location][:gift_card_payments] += transaction['amount'].to_f
            shopify_pos_sales_receipt_by_sale[order_name][:gift_card_payments] += transaction['amount'].to_f
          when 'shopify_payments'
            shopify_pos_sales_receipt[location][:credit_payments] += transaction['amount'].to_f
            shopify_pos_sales_receipt_by_sale[order_name][:credit_payments] += transaction['amount'].to_f
          end
        elsif transaction['kind'] == 'refund' && transaction['gateway'] == 'gift_card'
          if transaction['message'] == 'Another transaction failed so the gift card was rolled back'
            shopify_pos_sales_receipt[location][:gift_card_payments] -= transaction['amount'].to_f
            shopify_pos_sales_receipt_by_sale[order_name][:gift_card_payments] -= transaction['amount'].to_f
          end
        end
      end
    end

    #############################
    ####### Save Objects ########
    #############################

    ### Shopify Refunds ###

    refunded_amounts[:shipping] = refunded_amounts[:product_sales] + refunded_amounts[:sales_tax] + refunded_amounts[:refunded_shipping] + refunded_amounts[:arbitrary_discount] - refunded_amounts[:discount] - refunded_amounts[:total_payments]
    refunded_amounts[:location_costs] = refund_costs_by_location

    shopify_refund = ShopifyRefund.create!(refunded_amounts)

    refund_totals_by_pos_location.each do |location_id, values|
      values[:location_id] = location_id
      values[:shipping] = values[:product_sales] + values[:sales_tax] + values[:refunded_shipping] + values[:arbitrary_discount] - values[:discount] - values[:total_payments]
      shopify_refund.shopify_pos_refunds << ShopifyPosRefund.create!(values)
    end

    refund_totals_by_order.each do |order_name, values|
      values[:name] = order_name
      values[:shipping] = values[:product_sales] + values[:sales_tax] + values[:refunded_shipping] + values[:arbitrary_discount] - values[:discount] - values[:total_payments]
      shopify_refund.shopify_refund_orders << ShopifyRefundOrder.create!(values)
    end

    ### Shopify Sales Receipt Web ###

    shopify_sales_receipt = ShopifySalesReceipt.create!(shopify_sales_receipt)

    sales_totals_by_order.each do |order_name, values|
      values[:name] = order_name
      shopify_sales_receipt.shopify_sales_receipt_orders << ShopifySalesReceiptOrder.create!(values)
    end

    ### Shopify Sales Cost Web ###

    costs_report[:location_costs] = location_sales_costs
    shopify_sales_cost = ShopifySalesCost.create!(costs_report)

    costs_by_order.each do |order_name, values|
      values[:name] = order_name
      shopify_sales_cost.shopify_sales_cost_orders << ShopifySalesCostOrder.create!(values)
    end

    ### Shopify Sales Receipt Web (Wholesale) ###

    wholesale_shopify_sales_receipt[:store] = :wholesale
    wholesale_shopify_sales_receipt = ShopifySalesReceipt.create!(wholesale_shopify_sales_receipt)

    wholesale_sales_totals_by_order.each do |order_name, values|
      values[:name] = order_name
      values[:store] = :wholesale
      wholesale_shopify_sales_receipt.shopify_sales_receipt_orders << ShopifySalesReceiptOrder.create!(values)
    end

    ### Shopify Sales Costs Web (Wholesale) ###

    wholesale_costs_report[:location_costs] = wholesale_location_sales_costs
    wholesale_costs_report[:store] = :wholesale
    wholesale_shopify_sales_cost = ShopifySalesCost.create!(wholesale_costs_report)

    wholesale_costs_by_order.each do |order_name, values|
      values[:name] = order_name
      values[:store] = :wholesale
      wholesale_shopify_sales_cost.shopify_sales_cost_orders << ShopifySalesCostOrder.create!(values)
    end

    ### Shopify Sales Receipt Store ###

    shopify_pos_sales = DailyShopifyPosSale.create!(date: min_date)

    shopify_pos_sales_receipt.each do |location, receipt|
      receipt[:location] = location
      shopify_pos_sales.shopify_pos_sales_receipts << ShopifyPosSalesReceipt.create!(receipt)
    end

    shopify_pos_sales_receipt_by_sale.each do |order_name, receipt|
      receipt[:name] = order_name
      shopify_pos_sales.shopify_pos_sales_receipt_sales << ShopifyPosSalesReceiptSale.create!(receipt)
    end

    ### Shopify Sales Taxes Store (this might be obsolete) ###

    shopify_pos_sales_tax = shopify_pos_sales.create_shopify_pos_sales_tax
    shopify_pos_sales_tax.create_location_taxes

    ### Shopify Sales Cost Store ###

    shopify_pos_costs = DailyShopifyPosCost.create!(date: min_date)

    shopify_pos_sales_costs.each do |location, cost|
      cost[:location] = location
      shopify_pos_costs.shopify_pos_sales_costs << ShopifyPosSalesCost.create!(cost)
    end

    shopify_pos_sales_costs_by_sale.each do |order_name, cost|
      cost[:name] = order_name
      shopify_pos_costs.shopify_pos_sales_cost_orders << ShopifyPosSalesCostOrder.create!(cost)
    end

    #############################
    ######## send to QBO ########
    #############################

    begin
      shopify_sales_cost.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      shopify_refund.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      shopify_sales_receipt.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      wholesale_shopify_sales_cost.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      wholesale_shopify_sales_receipt.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      shopify_pos_costs.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end

    begin
      shopify_pos_sales.post_to_qbo
    rescue StandardError
      Airbrake.notify($ERROR_INFO)
    end
  end
end

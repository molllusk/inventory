namespace :daily_sales_receipts do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    day = 3.days.ago

    min_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    min_date -= min_date.utc_offset

    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day
    max_date -= max_date.utc_offset

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

    refunds = []
    refund_order_names = []
    order_names = []
    # variant_ids = []

    orders.each do |order|
      if %w(refunded partially_refunded).include?(order['financial_status'])
        sleep(0.5)
        order_refunds = ShopifyClient.refunds(order['id'])
        refund_order_names << order['name'] if order_refunds.present?
        order_refunds.each do |refund|
          refunds << refund if Time.parse(refund['created_at']) < min_date || Time.parse(refund['created_at']) > max_date
        end
      end

      next if Time.parse(order['closed_at']) < min_date || Time.parse(order['closed_at']) > max_date
      order_names << order['name']

      subtotal_price += order['subtotal_price'].to_f
      total_tax += order['total_tax'].to_f
      discount += order['total_discounts'].to_f
      sales_tax += order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      order['line_items'].each do |line_item|
        # variant_ids << line_item['variant_id']

        if line_item['gift_card'] || line_item['product_id'] == 1045344714837 # mollusk money
          gift_card_sales += line_item['price'].to_f
        else
          product_sales += line_item['price'].to_f
        end
      end

      shipping += order['shipping_lines'].reduce(0) { |sum, shipping_line| sum + shipping_line['price'].to_f }

      # sleep(0.5)

      # transactions = ShopifyClient.transactions(order['id'])

      # transactions.each do |transaction|
      #   next unless %w(capture sale).include?(transaction['kind']) && transaction['status'] == 'success'

      #   case transaction['gateway']
      #   when 'gift_card'
      #     gift_card_payments += transaction['amount'].to_f
      #   when 'paypal'
      #     paypal_payments += transaction['amount'].to_f
      #   when 'shopify_payments'
      #     shopify_payments += transaction['amount'].to_f
      #   end
      # end
    end

    # variant_ids = variant_ids.compact

    # inventory_item_ids = []

    # variant_ids.each do |variant_id|
    #   sleep(0.5)
    #   variant = ShopifyClient.get_variant(variant_id)
    #   inventory_item_ids << variant['inventory_item_id'] unless variant.blank?
    # end

    # inventory_item_ids = inventory_item_ids.compact

    # inventory_items = ShopifyClient.get_inventory_items(inventory_item_ids)

    # sum_costs = inventory_items.reduce(0) { |sum, inventory_item| sum + inventory_item['cost'].to_f }

    p order_names
    p refund_order_names

    refunded_amounts = Hash.new { |hash, key| hash[key] = { sub_total: 0, tax: 0, shipping: 0, discount: 0, shopify_payments: 0, paypal_payments: 0, gift_card_payments: 0, total_payments: 0 } }

    refunds.each do |refund|
      refund_date = Time.parse(refund['created_at'])
      next if refund_date < min_date || refund_date > max_date

      refund['refund_line_items'].each do |line_item|
        p line_item['location_id']
        refunded_amounts[line_item['location_id']][:sub_total] += line_item['subtotal'].to_f
        refunded_amounts[line_item['location_id']][:tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refunded_amounts[line_item['location_id']][:discount] += line_item['total_discount'].to_f # or do we want some allocated/set amount

        refunded_amounts[:total][:sub_total] += line_item['subtotal'].to_f
        refunded_amounts[:total][:tax] += line_item['total_tax'].to_f
        refunded_amounts[:total][:discount] += line_item['total_discount'].to_f
      end

      refund['transactions'].each do |transaction|
        next unless transaction['kind'] == 'refund' && transaction['status'] == 'success'

        case transaction['gateway']
        when 'gift_card'
          refunded_amounts[:total][:gift_card_payments] += transaction['amount'].to_f
          refunded_amounts[:total][:total_payments] += transaction['amount'].to_f
        when 'paypal'
          refunded_amounts[:total][:paypal_payments] += transaction['amount'].to_f
          refunded_amounts[:total][:total_payments] += transaction['amount'].to_f
        when 'shopify_payments'
          refunded_amounts[:total][:shopify_payments] += transaction['amount'].to_f
          refunded_amounts[:total][:total_payments] += transaction['amount'].to_f
        end
      end
    end

    refunded_shipping = refunded_amounts[:total][:total_payments] - refunded_amounts[:total][:sub_total] - refunded_amounts[:total][:tax]

    p refunded_amounts

    # ShopifySalesReceipt.create(
    #     date: 3.days.ago.beginning_of_day,
    #     product_sales: product_sales,
    #     discount: discount,
    #     gift_card_sales: gift_card_sales,
    #     shipping: shipping,
    #     sales_tax: sales_tax,
    #     shopify_payments: shopify_payments,
    #     paypal_payments: paypal_payments,
    #     gift_card_payments: gift_card_payments
    #   )

  end
end

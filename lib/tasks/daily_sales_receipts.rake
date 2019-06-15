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
    products = {}

    refunds = []
    refund_order_names = []
    order_names = []
    variant_ids = []

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

      order['line_items'].each do |line_item|
        variant_ids << line_item['variant_id']
        products[line_item['variant_id']] = line_item['product_id']

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

    variant_ids.compact!

    # inventory_item_ids = []
    missing_sd = []
    missing_barcode = []

    barcodes = variant_ids.map do |variant_id|
      sd = ShopifyDatum.find_by(variant_id: variant_id)
      missing_sd << variant_id if sd.blank?
      barcode = sd&.barcode
      missing_barcode << variant_id if barcode.blank?
      barcode
    end.compact

    puts "shit " * 100 if barcodes.length != variant_ids.length
    puts "Missing Shopify Datum Variant Ids"
    p missing_sd
    p missing_sd.map { |s| products[s] }
    puts "Missing Barcode on Shopify Datum Variant Ids"
    p missing_barcode

    missing_vends = []

    vend_products = barcodes.map do |barcode|
      vd = VendDatum.find_by(sku: barcode)
      missing_vends << barcode if vd.blank?
      vd
    end.compact

    puts "fuck " * 100 if barcodes.length != vend_products.length
    puts "Missing vend for shopify Barcodes:"
    p missing_vends

    # ShopifyInventory::locations.key(location_id)

    # inventory_item_ids << variant['inventory_item_id'] unless variant.blank?
    # end

    # inventory_item_ids = inventory_item_ids.compact

    # inventory_items = ShopifyClient.get_inventory_items(inventory_item_ids)

    # sum_costs = inventory_items.reduce(0) { |sum, inventory_item| sum + inventory_item['cost'].to_f }

    # p order_names
    # p refund_order_names

    refunded_amounts = Hash.new { |hash, key| hash[key] = { sub_total: 0, tax: 0, shipping: 0, discount: 0, shopify_payments: 0, paypal_payments: 0, gift_card_payments: 0, total_payments: 0 } }

    refunds.each do |refund|
      fulfillments = ShopifyClient.fulfillments(refund['order_id'])

      refund['refund_line_items'].each do |line_item|
        fulfillment = fulfillments.detect { |fulfillment| fulfillment['variant_id'] == line_item['variant_id'] }
        location_id = fulfillment['location_id'] || 'no_location'

        refund_discounts = line_item['line_item']['discount_allocations'].reduce(0) { |sum, discount_allocation| sum + discount_allocation['amount'].to_f }
        sub_total = line_item['line_item']['price'].to_f * line_item['quantity'].to_f

        refunded_amounts[location_id][:sub_total] += sub_total
        refunded_amounts[location_id][:tax] += line_item['total_tax'].to_f # or do we want tax lines total
        refunded_amounts[location_id][:discount] += refund_discounts

        refunded_amounts[:total][:sub_total] += sub_total
        refunded_amounts[:total][:tax] += line_item['total_tax'].to_f
        refunded_amounts[:total][:discount] += refund_discounts
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

    refunded_shipping = (refunded_amounts[:total][:sub_total] + refunded_amounts[:total][:tax] - refunded_amounts[:total][:discount]) - refunded_amounts[:total][:total_payments]

    p refunded_amounts

    # ShopifySalesReceipt.create(
    #     date: day.beginning_of_day,
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

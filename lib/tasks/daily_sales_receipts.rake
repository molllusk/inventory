namespace :daily_sales_receipts do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    orders = ShopifyClient.orders_closed_yesterday

    product_sales = 0.0
    discount = 0.0
    gift_card_sales = 0.0
    sales_tax = 0.0
    shipping = 0.0
    shopify_payments = 0.0
    paypal_payments = 0.0
    gift_card_payments = 0.0

    orders.each do |order|
      discount += order['total_discounts'].to_f
      sales_tax += order['tax_lines'].reduce(0) { |sum, tax_line| sum + tax_line['price'].to_f }

      order['line_items'].each do |line_item|
        if line_item['gift_card'] || line_item['product_id'] == 1045344714837 # mollusk money
          gift_card_sales += line_item['price'].to_f
        else
          product_sales += line_item['price'].to_f
        end
      end

      shipping += order['shipping_lines'].reduce(0) { |sum, shipping_line| sum + shipping_line['price'].to_f }

      ShopifyClient.transactions(order['id']).each do |transaction|
        next unless transaction['kind'] == 'capture'

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

    ShopifySalesReceipt.create(
        date: 1.day.ago.beginning_of_day,
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

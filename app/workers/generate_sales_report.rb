# frozen_string_literal: true

class GenerateSalesReport
  include Sidekiq::Worker
  sidekiq_options queue: :reporting, retry: false

  def perform(start_date, end_date)
    dates = {"start"=>"September 6, 2019", "end"=>"March 6, 2020"}

    # start_date = Date.parse(start_date) - 1.year
    # end_date = Date.parse(end_date) - 1.year

    start_date = Date.parse(dates["start"])
    end_date = Date.parse(dates["end"])


    begin_date = 1.year.ago.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    prior_ninety_days = begin_date - 90.days

    yesterday = Date.yesterday.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    ninety_days = 90.days.ago.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    raw_data_by_sku = {}
    
    product_types = Product.get_daily_order_inventory_levels.keys
  
    sales_by_type_and_size = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = Hash.new(0) } }

    raw_product_headers = Product.inventory_csv_headers

    sales_headers = [
      'Lead Up Vend',
      'Lead Up Shopify Retail',
      'Lead Up Shopify Wholesale',
      'Buy Period Vend',
      'Buy Period Shopify Retail',
      'Buy Period Shopify Wholesale',
      'Last 90 Days Vend',
      'Last 90 Days Shopify Retail',
      'Last 90 Days Shopify Wholesale',
      'Prior Last 90 Days Vend',
      'Prior Last 90 Days Shopify Retail',
      'Prior Last 90 Days Shopify Wholesale'
    ]

    raw_headers = raw_product_headers + sales_headers

    Product.find_each do |product|
      row_data = product.inventory_csv_row_data
      sales_headers.each { |header| row_data[header] = 0 }

      if product_types.include? row_data[:type].to_s.strip.downcase
        sales_by_type_and_size[row_data[:type].to_s][row_data[:size].to_s]['On-Hand Inventory'] += row_data[:total_inventory]
      end
      raw_data_by_sku[row_data[:sku]] ||= row_data
    end

    summary_headers = [
      :category,
      :size,
      'On-Hand Inventory',
      'Last Year Sales Present to Buy Period',
      'Last 90 Days',
      'Prior Last 90 Days',
      'YoY Change Last 90 Days',
      'Projected (Last Year) Sales for Buy Period',
      'Optimal Buy'
    ]

    shopify_orders = ShopifyClient.closed_orders_between(begin_date, start_date - 1.day)
    
    shopify_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Lead Up Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last Year Sales Present to Buy Period'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(start_date, end_date)

    shopify_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Buy Period Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Projected (Last Year) Sales during Buy Period'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(begin_date, start_date - 1.day, :WHOLESALE)

    shopify_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Lead Up Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last Year Sales Present to Buy Period'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(start_date, end_date, :WHOLESALE)

    shopify_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Buy Period Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Projected (Last Year) Sales during Buy Period'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(prior_ninety_days, begin_date - 1.day)

    shopify_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Prior Last 90 Days Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Prior Last 90 Days'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(ninety_days, yesterday)

    shopify_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Last 90 Days Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last 90 Days'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(prior_ninety_days, begin_date - 1.day, :WHOLESALE)

    shopify_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Prior Last 90 Days Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Prior Last 90 Days'] += quantity
          end
        end
      end
    end

    shopify_orders = ShopifyClient.closed_orders_between(ninety_days, yesterday, :WHOLESALE)

    shopify_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Last 90 Days Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last 90 Days'] += quantity
          end
        end
      end
    end

    vend_orders = VendClient.sales_range(begin_date, start_date - 1.day)

    vend_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Lead Up Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last Year Sales Present to Buy Period'] += quantity
          end
        end
      end
    end

    vend_orders = VendClient.sales_range(start_date, end_date)

    vend_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Buy Period Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Projected (Last Year) Sales during Buy Period'] += quantity
          end
        end
      end
    end

    vend_orders = VendClient.sales_range(prior_ninety_days, begin_date - 1.day)

    vend_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Prior Last 90 Days Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Prior Last 90 Days'] += quantity
          end
        end
      end
    end

    vend_orders = VendClient.sales_range(ninety_days, yesterday)

    vend_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[line_item['sku']]
        quantity = line_item['quantity']
        if product.present?
          product['Last 90 Days Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Last 90 Days'] += quantity
          end
        end
      end
    end

    xls = Spreadsheet::Workbook.new
    raw_sheet = xls.create_worksheet name: 'Sales Data'
    summary_sheet = xls.create_worksheet name: 'OTB Report'

    raw_sheet.row(0).concat raw_headers
    summary_sheet.row(0).concat summary_headers

    row = 1
    raw_data_by_sku.each do |sku, product|
      raw_sheet.row(row).concat raw_headers.map { |header| product[header] }
      row += 1
    end

    row = 1
    sales_by_type_and_size.each do |type, sales_by_size|
      sales_by_size.each do |size, sales|
        sales[:category] = type
        sales[:size] = size
        summary_sheet.row(row).concat summary_headers.map { |header| sales[header] }
        row += 1
      end
    end

    spreadsheet = StringIO.new
    xls.write spreadsheet 

    ApplicationMailer.otb_report(spreadsheet.string, start_date, end_date)
  end
end

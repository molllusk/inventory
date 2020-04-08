# frozen_string_literal: true

class GenerateOtbReport
  include Sidekiq::Worker
  sidekiq_options queue: :reporting, retry: false

  # Params format {"start"=>"March 27, 2020", "end"=>"February 15, 2021"}
  def perform(start_date, end_date)
    start_date = Date.parse(start_date) - 1.year
    end_date = Date.parse(end_date) - 1.year

    begin_date = 1.year.ago.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    prior_ninety_days = begin_date - 90.days

    today = Date.today.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    ninety_days = 90.days.ago.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    date_ranges_headers = ['Range','Start','End']
    date_ranges = []

    raw_data_by_sku = {}
    
    product_types = Product.get_daily_order_inventory_levels.keys
  
    sales_by_type_and_size = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = Hash.new(0) } }

    raw_product_headers = Product.inventory_csv_headers

    order_headers = ['Period', 'Date', 'Category', 'Size', 'Point of Sale', 'Sale id', 'SKU', 'Quantity']

    orders = []

    sales_headers = [
      'Lead Up Vend',
      'Lead Up Shopify Retail',
      'Lead Up Shopify Wholesale',
      'Buy Period Vend',
      'Buy Period Shopify Retail',
      'Buy Period Shopify Wholesale',
      'Sales Last 90 Days Vend',
      'Sales Last 90 Days Shopify Retail',
      'Sales Last 90 Days Shopify Wholesale',
      'Sales Last 90 Days Previous Year Vend',
      'Sales Last 90 Days Previous Year Shopify Retail',
      'Sales Last 90 Days Previous Year Shopify Wholesale'
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
      'category',
      'size',
      'On-Hand Inventory',
      'Sales Present to Buy Period',
      'Leftover Inventory',
      'Sales During Buy Period',
      'Sales Last 90 Days',
      'Sales Last 90 Days Previous Year',
      'YoY Change Last 90 Days (by type)',
      'Optimal Buy With Percentage',
      'Optimal Buy Without Percentage'
    ]

    missing_products = []

    # Begin Date
    date_ranges << ['Present to Buy Period', begin_date.strftime('%m/%d/%Y'), (start_date - 1.day).strftime('%m/%d/%Y')]

    query_orders = VendClient.sales_range(begin_date, start_date - 1.day)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[sku]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Present to Buy Period', retail_order['sale_date'], product[:type], product[:size], 'Vend', retail_order['id'], sku, quantity]
          product['Lead Up Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Present to Buy Period'] += quantity
          end
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(begin_date, start_date - 1.day)
    
    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Present to Buy Period', retail_order['created_at'], product[:type], product[:size], 'Shopify Retail', retail_order['id'], line_item['sku'], quantity]
          product['Lead Up Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Present to Buy Period'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(begin_date, start_date - 1.day, :WHOLESALE)

    query_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Present to Buy Period', wholesale_order['created_at'], product[:type], product[:size], 'Shopify Wholesale', wholesale_order['id'], line_item['sku'], quantity]
          product['Lead Up Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Present to Buy Period'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    # Start Date
    date_ranges << ['During Buy Period', start_date.strftime('%m/%d/%Y'), end_date.strftime('%m/%d/%Y')]

    query_orders = VendClient.sales_range(start_date, end_date)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[sku]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['During Buy Period', retail_order['sale_date'], product[:type], product[:size], 'Vend', retail_order['id'], sku, quantity]
          product['Buy Period Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales During Buy Period'] += quantity
          end
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(start_date, end_date)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['During Buy Period', retail_order['created_at'], product[:type], product[:size], 'Shopify Retail', retail_order['id'], line_item['sku'], quantity]
          product['Buy Period Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales During Buy Period'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(start_date, end_date, :WHOLESALE)

    query_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['During Buy Period', wholesale_order['created_at'], product[:type], product[:size], 'Shopify Wholesale', wholesale_order['id'], line_item['sku'], quantity]
          product['Buy Period Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales During Buy Period'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    # Ninety Days
    date_ranges << ['Last 90 Days', ninety_days.strftime('%m/%d/%Y'), today.strftime('%m/%d/%Y')]
    query_orders = VendClient.sales_range(ninety_days, today)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[sku]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days', retail_order['sale_date'], product[:type], product[:size], 'Vend', retail_order['id'], sku, quantity]
          product['Sales Last 90 Days Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days'] += quantity
          end
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(ninety_days, today)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days', retail_order['created_at'], product[:type], product[:size], 'Shopify Retail', retail_order['id'], line_item['sku'], quantity]
          product['Sales Last 90 Days Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(ninety_days, today, :WHOLESALE)

    query_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days', wholesale_order['created_at'], product[:type], product[:size], 'Shopify Wholesale', wholesale_order['id'], line_item['sku'], quantity]
          product['Sales Last 90 Days Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    # Prior Ninety Days
    date_ranges << ['Last 90 Days Previous Year', prior_ninety_days.strftime('%m/%d/%Y'), (begin_date - 1.day).strftime('%m/%d/%Y')]
    query_orders = VendClient.sales_range(prior_ninety_days, begin_date - 1.day)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        sku = VendDatum.where(vend_id: line_item['product_id']).pluck(:sku).first
        product = raw_data_by_sku[sku]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days Previous Year', retail_order['sale_date'], product[:type], product[:size], 'Vend', retail_order['id'], sku, quantity]
          product['Sales Last 90 Days Previous Year Vend'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days Previous Year'] += quantity
          end
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(prior_ninety_days, begin_date - 1.day)

    query_orders.each do |retail_order|
      retail_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days Previous Year', retail_order['created_at'], product[:type], product[:size], 'Shopify Retail', retail_order['id'], line_item['sku'], quantity]
          product['Sales Last 90 Days Previous Year Shopify Retail'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days Previous Year'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    query_orders = ShopifyClient.closed_orders_between(prior_ninety_days, begin_date - 1.day, :WHOLESALE)

    query_orders.each do |wholesale_order|
      wholesale_order['line_items'].each do |line_item|
        product = raw_data_by_sku[ShopifyDatum.find_by(sku: line_item['sku'])&.barcode]
        quantity = line_item['quantity'].to_i
        if product.present?
          orders << ['Last 90 Days Previous Year', wholesale_order['created_at'], product[:type], product[:size], 'Shopify Wholesale', wholesale_order['id'], line_item['sku'], quantity]
          product['Sales Last 90 Days Previous Year Shopify Wholesale'] += quantity
          if product_types.include? product[:type].to_s.strip.downcase
            sales_by_type_and_size[product[:type].to_s][product[:size].to_s]['Sales Last 90 Days Previous Year'] += quantity
          end
        else
          missing_products << line_item['sku']
        end
      end
    end

    xls = Spreadsheet::Workbook.new
    otb_sheet = xls.create_worksheet name: 'OTB Report'
    products_sheet = xls.create_worksheet name: 'Products'
    orders_sheet = xls.create_worksheet name: 'Orders'
    date_ranges_sheet = xls.create_worksheet name: 'Date Ranges'

    products_sheet.row(0).concat raw_headers.map { |h| h.to_s }
    otb_sheet.row(0).concat summary_headers.map { |h| h.to_s }
    orders_sheet.row(0).concat order_headers.map { |h| h.to_s }
    date_ranges_sheet.row(0).concat date_ranges_headers

    date_ranges.each_with_index do |range, row|
      date_ranges_sheet.row(row + 1).concat range
    end

    row = 1
    raw_data_by_sku.each do |sku, product|
      products_sheet.row(row).concat raw_headers.map { |header| product[header] }
      row += 1
    end

    row = 1
    sales_by_type_and_size.each do |type, sales_by_size|
      yoy = 0.0
      last_ninety = 0.0
      prior_last_ninety = 0.0

      # Looping over this twice is gross
      sales_by_size.each do |type, sales|
        last_ninety += sales['Sales Last 90 Days']
        prior_last_ninety += sales['Sales Last 90 Days Previous Year']
      end

      yoy = (last_ninety - prior_last_ninety) / prior_last_ninety

      sales_by_size.each do |size, sales|
        sales['category'] = type
        sales['size'] = size
        sales['YoY Change Last 90 Days (by type)'] = yoy

        sales['Leftover Inventory'] = sales['Sales Present to Buy Period'] < sales['On-Hand Inventory'] ? sales['On-Hand Inventory'] - sales['Sales Present to Buy Period'] : 0

        sales['Optimal Buy With Percentage'] = sales['Sales During Buy Period'] * (1 + yoy) - sales['Leftover Inventory']

        sales['Optimal Buy Without Percentage'] = sales['Sales During Buy Period'] - sales['Leftover Inventory']

        otb_sheet.row(row).concat summary_headers.map { |header| sales[header] }
        row += 1
      end
    end

    orders.each_with_index do |order, row|
      orders_sheet.row(row + 1).concat order
    end

    spreadsheet = StringIO.new
    xls.write spreadsheet 

    ApplicationMailer.otb_report(spreadsheet.string, start_date, end_date).deliver
  end
end

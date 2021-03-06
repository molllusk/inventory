# frozen_string_literal: true

class VendClient
  BASE_URL = 'https://mollusksurf.vendhq.com/api/2.0'

  OUTLET_NAMES_BY_ID = {
    '5e234f4e-8eed-11e0-8e09-4040f540b50a' => 'San Francisco',
    '8d27bed3-060b-11e4-a0f5-b8ca3a64f8f4' => 'Santa Barbara',
    '0adfd74a-153e-11e9-fa42-67b5781ba1fb' => 'Venice Beach'
  }.freeze

  SAVED_ATTRIBUTES = %i[
    active
    brand_id
    handle
    has_inventory
    has_variants
    is_active
    name
    product_type_id
    sku
    supplier_id
    supply_price
    variant_count
    variant_name
    variant_parent_id
    brand
    supplier
    variant_options
    tag_ids
    categories
  ].freeze

  def self.connection
    sleep(0.8)
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.authorization :Bearer, ENV['VEND_TOKEN']
      faraday.request  :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.paginator(path)
    page = 0
    data = []
    loop do
      retries = 0
      begin
        response = connection.get path, { after: page }
      rescue StandardError
        if (retries += 1) < 5
          sleep(retries)
          retry
        end
      end
      break if response.body['data'].blank?

      data += response.body['data']
      page = response.body['version']['max']
    end
    data
  end

  def self.get_item(resource, id)
    retries = 0
    response = nil

    begin
      response = connection.get "#{resource}/#{id}"
    rescue StandardError
      if (retries += 1) < 5
        sleep(retries)
        retry
      end
    end

    if response&.body
      response.body['data'] || {}
    else
      {}
    end
  end

  def self.all_products
    paginator('products')
  end

  def self.active_products
    all_products.select { |product| product['is_active'] }
  end

  def self.sales_range(start_date, end_date)
    min_date =  start_date.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    min_date -= min_date.utc_offset
    max_date = end_date.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day
    max_date -= max_date.utc_offset

    end_query_date = min_date + 1.week
    full_data = []

    loop do
      weekly_data = []

      loop do
        retries = 0
        begin
          response = connection.get 'search', { page_size: 1000, type: 'sales', date_from: min_date.iso8601, date_to: end_query_date.iso8601, offset: weekly_data.length }
        rescue StandardError
          if (retries += 1) < 5
            sleep(retries)
            retry
          end
        end
        break if response.body['data'].blank?

        weekly_data += response.body['data']
      end
      full_data += weekly_data

      break if end_query_date == max_date

      min_date = end_query_date
      end_query_date += 1.week
      end_query_date = max_date if end_query_date > max_date
    end
    full_data
  end

  def self.sales(day)
    min_date =  day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    min_date -= min_date.utc_offset
    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day
    max_date -= max_date.utc_offset

    data = []

    loop do
      retries = 0
      begin
        response = connection.get 'search', { page_size: 1000, type: 'sales', date_from: min_date.iso8601, date_to: max_date.iso8601, offset: data.length }
      rescue StandardError
        if (retries += 1) < 5
          sleep(retries)
          retry
        end
      end

      break if response.body['data'].blank?

      data += response.body['data']
    end

    data
  end

  def self.daily_orders
    min_version = Redis.current.get('min_daily_order_version').to_i

    response = connection.get 'consignments', { page_size: 500, type: 'SUPPLIER', status: 'SENT', after: min_version }
    response.body['data']
  end

  def self.consignments
    min_version = Redis.current.get('min_consignment_version').to_i

    response = connection.get 'consignments', { page_size: 500, type: 'OUTLET', status: 'RECEIVED', after: min_version }
    response.body['data']
  end

  def self.consignment_products(consignment_id)
    paginator("consignments/#{consignment_id}/products")
  end

  def self.create_consignment(daily_order)
    body = {
      type: 'SUPPLIER',
      status: 'OPEN',
      name: daily_order.display_po,
      outlet_id: daily_order.outlet_id
    }

    response = connection.post do |req|
      req.url 'consignments'
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body['data']
  end

  def self.add_consignment_product(order)
    body = {
      product_id: order.product.vend_datum.vend_id,
      count: order.quantity,
      received: nil,
      cost: order.total_cost
    }

    response = connection.post do |req|
      req.url "consignments/#{order.daily_order.vend_consignment_id}/products"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body['data']
  end

  def self.update_consignment_status(consignment_id, status)
    body = { status: status }

    response = connection.put do |req|
      req.url "consignments/#{consignment_id}"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body['data']
  end

  def self.get_inventory
    paginator('inventory')
  end

  def self.product_attributes(product)
    cleaned = {
      vend_id: product['id'],
      vend_created_at: product['created_at'],
      vend_deleted_at: product['deleted_at'],
      vend_type: product['type']
    }

    SAVED_ATTRIBUTES.each { |saved_attribute| cleaned[saved_attribute] = product[saved_attribute.to_s] }
    cleaned
  end
end

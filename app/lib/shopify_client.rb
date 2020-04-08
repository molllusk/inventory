module ShopifyClient
  RETAIL_BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze
  WHOLESALE_BASE_URL = "https://#{ENV['WHOLESALE_SHOPIFY_USER']}:#{ENV['WHOLESALE_SHOPIFY_PASSWORD']}@molluskats.myshopify.com".freeze
  API_VERSION = '/admin/api/2020-04'.freeze

  SAVED_PRODUCT_ATTRIBUTES = %i[
    handle
    product_type
    title
    vendor
  ]

  SAVED_VARIANT_ATTRIBUTES = %i[
    barcode
    compare_at_price
    fulfillment_service
    grams
    inventory_item_id
    inventory_management
    inventory_policy
    inventory_quantity
    old_inventory_quantity
    option1
    option2
    option3
    price
    requires_shipping
    sku
    weight
    weight_unit
  ]

  def self.connection(store = :RETAIL)
    sleep(0.5)
    Faraday.new(url: const_get("#{store.to_s.upcase}_BASE_URL")) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.all_inventory_locations(store = :RETAIL)
     response = connection(store).get "#{API_VERSION}/locations.json"
     response.body['locations']
  end

  def self.count(resource, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/#{resource}/count.json"
    response.body['count']
  end

  def self.all_products(store = :RETAIL)
    all_resource('products', store)
  end

  def self.all_resource(resource, store = :RETAIL)
    params = { limit: 250 }
    cursor_paginate(resource, params, store)
  end

  def self.all_orders(store = :RETAIL)
    all_resource('orders', store)
  end

  # Final order quantity needs to account for refunded items
  def self.order_quantities_by_variant(store = :RETAIL)
    orders = Hash.new(0)
    refunds = Hash.new(0)

    all_orders(store).each do |order|
      next if %w(fulfilled restocked).include? order['fulfillment_status']

      order['refunds'].each do |refund|
        refund['refund_line_items'].each do |refund_line_item|
          refunds[refund_line_item['line_item_id']] += refund_line_item['quantity']
        end
      end

      order['line_items'].each do |line_item|
        if line_item['fulfillment_status'].blank?
          orders[line_item['variant_id']] += line_item['quantity'] - refunds[line_item['id']]
        end
      end
    end
    orders
  end

  def self.connect_inventory_location(inventory_item_id, location_id, store = :RETAIL)
    body = {
      'location_id': location_id,
      'inventory_item_id': inventory_item_id
    }

    response = connection(store).post do |req|
      req.url "#{API_VERSION}/inventory_levels/connect.json"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body
  end

  def self.get_inventory_levels_all_locations(inventory_item_ids, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}&limit=250"
    response.body['inventory_levels'] || []
  end

  def self.get_inventory_items(inventory_item_ids, store = :RETAIL)
    inventory_items = []

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      response = connection(store).get "#{API_VERSION}/inventory_items.json?ids=#{id_batch.join(',')}&limit=250"
      inventory_items << response.body['inventory_items'] unless response.body['inventory_items'].blank?
    end

    inventory_items.flatten
  end

  def self.get_inventory_item(inventory_item_id, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/inventory_items/#{inventory_item_id}.json"
    response.body['inventory_item'] || {}
  end

  def self.get_variant(variant_id, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/variants/#{variant_id}.json"
    response.body['variant'] || {}
  end

  def self.get_cost(variant_id, store = :RETAIL)
    variant = get_variant(variant_id, store)
    return unless variant.present?

    inventory_item_id = variant['inventory_item_id']
    inventory_item = get_inventory_item(inventory_item_id, store)
    return unless inventory_item.present?

    inventory_item['cost'].to_f
  end

  def self.update_inventories(store = :RETAIL)
    inventory_item_ids = ShopifyDatum.where(store: store.to_s.downcase).pluck(:inventory_item_id)

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      all_inventory_levels = get_inventory_levels_all_locations(id_batch, store)

      all_inventory_levels.each do |inventory_level|
        sd = ShopifyDatum.find_by(inventory_item_id: inventory_level['inventory_item_id'])
        existing_inventory_item = sd.shopify_inventories.find_by(location: inventory_level['location_id'])
        if inventory_level['available'].present?
          if existing_inventory_item.present?
            existing_inventory_item.update_attribute(:inventory, inventory_level['available']) if existing_inventory_item.inventory != inventory_level['available']
          else
            sd.shopify_inventories << ShopifyInventory.create(location: inventory_level['location_id'], inventory: inventory_level['available'])
          end
        end
      end
    end
  end

  def self.adjust_inventory(inventory_item_id, location_id, adjustment, store = :RETAIL)
    body = {
      'location_id': location_id,
      'inventory_item_id': inventory_item_id,
      'available_adjustment': adjustment
    }

    response = connection(store).post do |req|
      req.url "#{API_VERSION}/inventory_levels/adjust.json"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body
  end

  def self.inventory_item_updated?(response)
    response.present? && response['inventory_level'].present?
  end

  def self.products_attributes(product)
    products = []

    cleaned = {
      shopify_created_at: product['created_at'],
      shopify_product_id: product['id'],
      tags: product['tags'].split(',')
    }

    SAVED_PRODUCT_ATTRIBUTES.each { |saved_attribute| cleaned[saved_attribute] = product[saved_attribute.to_s] }

    product['variants'].each do |variant|
      products << variant_attributes(cleaned.clone, variant)
    end
    products
  end

  def self.variant_attributes(attributes, variant)
    attributes[:variant_id] = variant['id']
    attributes[:variant_created_at] = variant['created_at']
    attributes[:variant_title] = variant['title']

    SAVED_VARIANT_ATTRIBUTES.each { |saved_attribute| attributes[saved_attribute] = variant[saved_attribute.to_s] }
    attributes
  end

  def self.closed_orders_since_count(day, store = :RETAIL)
    min_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    count_params = {
      status: 'closed',
      updated_at_min: min_date,
    }

    count_response = connection(store).get "#{API_VERSION}/orders/count.json", count_params
    count_response.body['count'].to_i
  end

  def self.closed_orders_since(day, store = :RETAIL)
    min_date =  day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day

    params = {
      limit: 250,
      status: 'closed',
      updated_at_min: min_date
    }

    cursor_paginate('orders', params, store)
  end

  def self.closed_orders_between_count(start_date, end_date, store = :RETAIL)
    min_date = start_date.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    max_date = end_date.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day

    count_params = {
      status: 'closed',
      created_at_min: min_date,
      created_at_max: max_date
    }

    count_response = connection(store).get "#{API_VERSION}/orders/count.json", count_params
    count_response.body['count'].to_i
  end

  def self.closed_orders_between(start_date, end_date, store = :RETAIL)
    min_date = start_date.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    max_date = end_date.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day

    params = {
      limit: 250,
      status: 'closed',
      created_at_min: min_date,
      created_at_max: max_date
    }

    cursor_paginate('orders', params, store)
  end

  def self.transactions(order_id, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/orders/#{order_id}/transactions.json"
    response.body['transactions'] || []
  end

  def self.fulfillments(order_id, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/orders/#{order_id}/fulfillments.json"
    response.body['fulfillments'] || []
  end

  def self.refunds(order_id, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/orders/#{order_id}/refunds.json"
    response.body['refunds'] || []
  end

  # Pagination methods https://www.shopify.com/partners/blog/relative-pagination
  def self.cursor_paginate(resource, params, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/#{resource}.json", params
    resources = response.body[resource]

    loop do
      links = response.headers['link']
      break unless links.present?

      next_link = next_page_link(links)
      break unless next_link.present?

      response = connection(store).get next_page_url(next_link)
      resources += response.body[resource]
    end

    resources || []
  end

  def self.next_page_link(links)
    links.split(', ').find { |link| link.include?("rel=\"next\"") }
  end

  def self.next_page_url(next_link)
    next_link.split(';').first.gsub(/\<|\>/, '')
  end
end

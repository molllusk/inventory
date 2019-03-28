class ShopifyClient
  RETAIL_BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze
  WHOLESALE_BASE_URL = "https://#{ENV['WHOLESALE_SHOPIFY_USER']}:#{ENV['WHOLESALE_SHOPIFY_PASSWORD']}@molluskats.myshopify.com".freeze
  SF_RETAIL_INVENTORY_LOCATION = 49481991
  JAM_WHOLESALE_INVENTORY_LOCATION = 29887823936

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
    price
    requires_shipping
    sku
    weight
    weight_unit
  ]

  def self.connection(store = :RETAIL)
    Faraday.new(url: const_get("#{store.to_s.upcase}_BASE_URL")) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.count(resource, store = :RETAIL)
    response = connection(store).get "/admin/#{resource}/count.json"
    response.body['count']
  end

  def self.all_products(store = :RETAIL)
    all_resource('products', store)
  end

  def self.all_resource(resource, store = :RETAIL)
    resources = []
    pages = (count(resource, store) / 250.0).ceil
    pages.times do |page|
      response = connection(store).get "/admin/#{resource}.json", { limit: 250, page: page + 1 }
      resources += response.body[resource]
    end
    resources
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
      req.url '/admin/inventory_levels/connect.json'
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body
  end

  def self.connect_sf_inventory_location(inventory_item_id)
    connect_inventory_location(inventory_item_id, SF_RETAIL_INVENTORY_LOCATION)
  end

  def self.get_inventory_items_all_locations(inventory_item_ids, store = :RETAIL)
    response = connection(store).get "/admin/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}"
    response.body['inventory_levels']
  end

  def self.get_inventory_items(inventory_item_ids, store = :RETAIL)
    response = connection(store).get "/admin/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}&location_ids=#{inventory_location(store)}&limit=250"
    response.body['inventory_levels']
  end

  def self.update_inventories(store = :RETAIL)
    inventory_item_ids = ShopifyDatum.pluck(:inventory_item_id)
    orders = order_quantities_by_variant(store)

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      inventory_items = get_inventory_items(id_batch, store)
      inventory_items.each do |inventory_item|
        sd = ShopifyDatum.find_by_inventory_item_id(inventory_item['inventory_item_id'])
        if inventory_item['available'].present?
          current_inventory = inventory_item['available'] + orders[sd.variant_id]
          sd.update_attribute(:inventory, current_inventory) unless sd.inventory == current_inventory
        end
      end
    end
  end

  def self.adjust_inventory(inventory_item_id, adjustment, store = :RETAIL)
    body = {
      'location_id': inventory_location(store),
      'inventory_item_id': inventory_item_id,
      'available_adjustment': adjustment
    }

    response = connection(store).post do |req|
      req.url '/admin/inventory_levels/adjust.json'
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

  def self.inventory_location(store = :RETAIL)
    store.to_s.upcase == 'RETAIL' ? SF_RETAIL_INVENTORY_LOCATION : JAM_WHOLESALE_INVENTORY_LOCATION
  end
end

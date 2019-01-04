class ShopifyClient
  BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze
  SF_INVENTORY_LOCATION = 49481991
  SF_ORIGIN_LOCATION = 280914881

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

  def self.connection
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.count(resource)
    response = connection.get "/admin/#{resource}/count.json"
    response.body['count']
  end

  def self.all_products
    all_resource('products')
  end

  def self.all_resource(resource)
    resources = []
    pages = (count(resource) / 250.0).ceil
    pages.times do |page|
      response = connection.get "/admin/#{resource}.json", { limit: 250, page: page + 1 }
      resources += response.body[resource]
    end
    resources
  end

  def self.all_orders
    all_resource('orders')
  end

  def self.order_quantities_by_variant
    orders = Hash.new(0)
    all_orders.each do |order|
      next if %w(fulfilled restocked).include? order['fulfillment_status']
      order['line_items'].each do |line_item|
        orders[line_item['variant_id']] += line_item['quantity'] if line_item['fulfillment_status'].blank? && line_item['origin_location']['id'] == SF_ORIGIN_LOCATION
      end
    end
    orders
  end

  def self.get_inventory_items_all_locations(inventory_item_ids)
    response = connection.get "/admin/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}"
    response.body['inventory_levels']
  end

  def self.get_inventory_items_sf(inventory_item_ids)
    response = connection.get "/admin/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}&location_ids=#{SF_INVENTORY_LOCATION}&limit=250"
    response.body['inventory_levels']
  end

  def self.get_sf_inventory(inventory_item_id)
    inventory_item = get_inventory_items_sf([inventory_item_id])
    inventory_item.first['available'] if inventory_item.first.present?
  end

  def self.update_inventories
    inventory_item_ids = ShopifyDatum.pluck(:inventory_item_id)

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      inventory_items = ShopifyClient.get_inventory_items_sf(id_batch)
      inventory_items.each do |inventory_item|
        sd = ShopifyDatum.find_by_inventory_item_id(inventory_item['inventory_item_id'])
        sd.update_attribute(:inventory, inventory_item['available']) unless sd.inventory == inventory_item['available']
      end
    end
  end

  def self.set_inventory(inventory, adjustment)
    body = {
      'location_id': inventory['location_id'],
      'inventory_item_id': inventory['inventory_item_id'],
      'available_adjustment': adjustment
    }

    response = connection.post do |req|
      req.url '/admin/inventory_levels/adjust.json'
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body
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

  def self.save_shopify_variants(shopify_product)
    products = products_attributes(shopify_product)
    products.each do |product_data|
      if VendDatum.exists?(sku: product_data[:sku])
        product = VendDatum.find_by_sku(product_data[:sku]).product
        product_data[:product_id] = product.id
        ShopifyDatum.create(product_data)
      end
    end
  end
end

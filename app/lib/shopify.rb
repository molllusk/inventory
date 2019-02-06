class ShopifyClient
  BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze
  SF_INVENTORY_LOCATION = 49481991
  # this was used when we thought origin location on an order meant the store where it was to be fulfilled from.
  # SF_ORIGIN_LOCATION = 280914881

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

  # Final order quantity needs to account for refunded items
  def self.order_quantities_by_variant
    orders = Hash.new(0)
    refunds = Hash.new(0)

    all_orders.each do |order|
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
    orders = order_quantities_by_variant

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      inventory_items = ShopifyClient.get_inventory_items_sf(id_batch)
      inventory_items.each do |inventory_item|
        sd = ShopifyDatum.find_by_inventory_item_id(inventory_item['inventory_item_id'])
        if inventory_item['available'].present?
          current_inventory = inventory_item['available'] + orders[sd.variant_id]
          sd.update_attribute(:inventory, current_inventory) unless sd.inventory == current_inventory
        end
      end
    end
  end

  def self.adjust_inventory(inventory_item_id, adjustment)
    body = {
      'location_id': SF_INVENTORY_LOCATION,
      'inventory_item_id': inventory_item_id,
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
end

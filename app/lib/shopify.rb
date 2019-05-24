class ShopifyClient
  RETAIL_BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze
  WHOLESALE_BASE_URL = "https://#{ENV['WHOLESALE_SHOPIFY_USER']}:#{ENV['WHOLESALE_SHOPIFY_PASSWORD']}@molluskats.myshopify.com".freeze
  SF_RETAIL_INVENTORY_LOCATION = 49481991.freeze
  JAM_WHOLESALE_INVENTORY_LOCATION = 29887823936.freeze
  API_VERSION = '/admin/api/2019-04'.freeze

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
    resources = []
    pages = (count(resource, store).to_i / 250.0).ceil
    pages.times do |page|
      response = connection(store).get "#{API_VERSION}/#{resource}.json", { limit: 250, page: page + 1 }
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
      req.url "#{API_VERSION}/inventory_levels/connect.json"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body
  end

  def self.get_inventory_items_all_locations(inventory_item_ids, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}&limit=250"
    response.body['inventory_levels'] || []
  end

  # Might be able to get rid of or replace this
  def self.get_inventory_items(inventory_item_ids, store = :RETAIL)
    response = connection(store).get "#{API_VERSION}/inventory_levels.json?inventory_item_ids=#{inventory_item_ids.join(',')}&location_ids=#{inventory_location(store)}&limit=250"
    response.body['inventory_levels'] || []
  end

  # might be able to get rid of and replace this and the inventory location constants
  def self.inventory_location(store = :RETAIL)
    store.to_s.upcase == 'RETAIL' ? SF_RETAIL_INVENTORY_LOCATION : JAM_WHOLESALE_INVENTORY_LOCATION
  end

  def self.update_inventories(store = :RETAIL)
    inventory_item_ids = ShopifyDatum.where(store: store.to_s.downcase).pluck(:inventory_item_id)

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      all_inventory_items = get_inventory_items_all_locations(id_batch, store)

      all_inventory_items.each do |inventory_item|
        sd = ShopifyDatum.find_by(inventory_item_id: inventory_item['inventory_item_id'])
        existing_inventory_item = sd.shopify_inventories.find_by(location: inventory_item['location_id'])
        if inventory_item['available'].present?
          if existing_inventory_item.present?
            existing_inventory_item.update_attribute(:inventory, inventory_item['available']) if existing_inventory_item.inventory != inventory_item['available'] 
          else
            sd.shopify_inventories << ShopifyInventory.create(location: inventory_item['location_id'], inventory: inventory_item['available'])
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
end

class VendClient
  BASE_URL = 'https://mollusksurf.vendhq.com/api/2.0'.freeze

  OUTLET_NAMES_BY_ID = {
    '5e234f4e-8eed-11e0-8e09-4040f540b50a' => 'San Francisco',
    '8d27bed3-060b-11e4-a0f5-b8ca3a64f8f4' => 'Silver Lake',
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
  ]

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
      response = connection.get path, { after: page }
      break if response.body['data'].blank?
      data += response.body['data']
      page = response.body['version']['max']
    end
    data
  end

  def self.all_products
    paginator('products')
  end

  def self.active_products
    all_products.select { |product| product['is_active'] }
  end

  def self.sales(day)
    min_date =  day.to_time.in_time_zone('Pacific Time (US & Canada)').beginning_of_day
    min_date -= min_date.utc_offset
    max_date = day.to_time.in_time_zone('Pacific Time (US & Canada)').end_of_day
    max_date -= max_date.utc_offset

    response = connection.get 'search', { page_size: 10000, type: 'sales', date_from: min_date.iso8601, date_to: max_date.iso8601 }
    response.body['data']
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
    response = connection.get "consignments/#{consignment_id}/products", { page_size: 500 }
    response.body['data']
  end

  def self.create_consignment(daily_order)
    body = {
      type: "SUPPLIER",
      status: "OPEN",
      name: daily_order.display_po,
      outlet_id: daily_order.outlet_id
    }

    response = connection.post do |req|
      req.url "consignments"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body['data']
  end

  def self.add_consignment_product(order)
    body = {
      product_id: order.product.vend_datum.vend_id,
      count: order.quantity,
      received: null,
      cost: order.total_cost
    }

    response = connection.post do |req|
      req.url "consignments/#{order.daily_order.vend_consignment_id}/products"
      req.headers['Content-Type'] = 'application/json'
      req.body = body.to_json
    end

    response.body['data']
  end

  def self.get_inventory
    paginator('inventory')
  end

  def self.get_sf_inventory
    get_inventory.select { |inventory| inventory['outlet_id'] == OUTLET_NAMES_BY_ID.key("San Francisco") }
  end

  def self.update_inventories
    all_inventory_levels = get_inventory

    all_inventory_levels.each do |inventory_level|
      vd = VendDatum.find_by(vend_id: inventory_level['product_id'])

      if vd.present?
        existing_inventory_item = vd.vend_inventories.find_by(outlet_id: inventory_level['outlet_id'])
        if existing_inventory_item.present?
          existing_inventory_item.update_attribute(:inventory, inventory_level['inventory_level']) unless existing_inventory_item.inventory == inventory_level['inventory_level']
        else
          vd.vend_inventories << VendInventory.create(outlet_id: inventory_level['outlet_id'], inventory: inventory_level['inventory_level'])
        end
      end
    end
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

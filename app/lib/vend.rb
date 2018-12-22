class VendClient
  BASE_URL = "https://mollusksurf.vendhq.com/api/2.0".freeze

  SAVED_ATTRIBUTES = %i[
    active
    brand_id
    description
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
      response = connection.get path, { outlet_id: ENV['VEND_OUTLET_ID'] , after: page }
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

  def self.get_inventory
    paginator('inventory')
  end

  def self.update_inventory
    inventories = get_inventory
    VendDatum.find_each do |product|
      inventory = inventories.find { |iv| iv['product_id'] == product.vend_id }
      if inventory.present?
        vd.update_attribute(:inventory, inventory['inventory_level']) unless vd.inventory == inventory['inventory_level']
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

  def self.create_product(product)
    vd = VendDatum.new(product_attributes(product))
    vd.product = Product.create
    if vd.save
      return vd.product
    end
  end
end

class ShopifyClient
  BASE_URL = "https://#{ENV['SHOPIFY_USER']}:#{ENV['SHOPIFY_PASSWORD']}@mollusksurf.myshopify.com".freeze

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

  def self.product_count
    response = connection.get 'admin/products/count.json'
    response.body['count']
  end

  def self.all_products
    products = []
    pages = (product_count / 250.0).ceil
    pages.times do |page|
      response = connection.get '/admin/products.json', { limit: 250, page: page + 1 }
      products += response.body['products']
    end
    products
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
      products << variant_attributes(cleaned, variant)
    end
    products
  end

  def self.variant_attributes(attributes, variant)
    attributes[:variant_id] = variant['id']
    attributes[:variant_created_at] = variant['created_at']
    attributes[:variant_title] = variant['title']

    SAVED_VARIANT_ATTRIBUTES.each { |saved_attribute| attributes[saved_attribute] = variant[saved_attribute.to_s]}
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

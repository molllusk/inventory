class ShopifyClient
  USER = ENV['SHOPIFY_USER'].freeze
  PASSWORD = ENV['SHOPIFY_PASSWORD'].freeze
  BASE_URL = "https://#{USER}:#{PASSWORD}@mollusksurf.myshopify.com".freeze

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
end

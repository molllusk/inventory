class VendClient
  BASE_URL = "https://mollusksurf.vendhq.com/api/2.0".freeze
  VEND_TOKEN = ENV['VEND_TOKEN'].freeze
  OUTLET_ID = ENV['VEND_OUTLET_ID'].freeze

  def self.connection
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.authorization :Bearer, VEND_TOKEN
      faraday.request  :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.paginator(path)
    page = 0
    data = []
    loop do
      response = connection.get path, { outlet_id: OUTLET_ID, after: page }
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

  def self.inventory
    paginator('inventory')
  end
end

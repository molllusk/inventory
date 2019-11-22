class SosClient
  BASE_URL = 'https://api.sosinventory.com/api/v2'.freeze

  def self.connection
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.authorization :Bearer, "6vFUA9YnEsG6UHB9t2c71CxPB3FnW0YdyMNADejF3f8BwBEUNepyyF3rPVFU9DENX_SYlSAAva2LFJL4HW7tA6_iJF8n-QKDwm3hwyGWG8OqmM-E_rY7xcwLgGiA4fKXvYE_zilVLJWvnBQUqpRbC0u9a7bz0MOvZp9HkojmjrhoKl4F5WiiWrziGeQnXIWYYoxXMT_bQ9wHzWDAO4oEPJMJpJRkzTVYKr-wuXwYF_T59g9XMems1D9C3mrIqKyQKQoFQhb6r7dXNeCGclHvmosOQOxHaMHQApV3F1b_PTubwIGQ3VHyMMtct_51XiJ0QlueHA"
      faraday.request  :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.get_customers
    connection.get('customer').body['data']
  end

  def self.get_locations
    connection.get('location').body['data']
  end

  def self.get_channels
    connection.get('channel').body['data']
  end

  def self.get_terms
    connection.get('terms').body['data']
  end
end

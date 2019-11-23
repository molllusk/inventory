class SosClient
  BASE_URL = 'https://api.sosinventory.com/api/v2'.freeze

  def self.connection
    sleep(0.1)
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.authorization :Bearer, "6vFUA9YnEsG6UHB9t2c71CxPB3FnW0YdyMNADejF3f8BwBEUNepyyF3rPVFU9DENX_SYlSAAva2LFJL4HW7tA6_iJF8n-QKDwm3hwyGWG8OqmM-E_rY7xcwLgGiA4fKXvYE_zilVLJWvnBQUqpRbC0u9a7bz0MOvZp9HkojmjrhoKl4F5WiiWrziGeQnXIWYYoxXMT_bQ9wHzWDAO4oEPJMJpJRkzTVYKr-wuXwYF_T59g9XMems1D9C3mrIqKyQKQoFQhb6r7dXNeCGclHvmosOQOxHaMHQApV3F1b_PTubwIGQ3VHyMMtct_51XiJ0QlueHA"
      faraday.request  :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.paginator(path)
    num_requests = 0
    start = 0
    data = []
    loop do
      response = connection.get path, { start: start }
      break if response.body['data'].blank?
      data += response.body['data']
      break if response.body['data'].count < 200
      num_requests += 1
      start = num_requests * 200 + 1
    end
    data
  end

  def self.get_customers
    paginator('customer')
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

  def self.get_items
    paginator('item')
  end

  def self.get_sales_reps
    connection.get('salesrep').body['data']
  end

  def self.create_sales_order(data)
    response = connection.post do |req|
      req.url "#{BASE_URL}/salesorder"
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end

    response.body['data']
  end
end

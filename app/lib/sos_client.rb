# frozen_string_literal: true

class SosClient
  BASE_URL = 'https://api.sosinventory.com/api/v2'
  AUTH_URL = 'https://api.sosinventory.com/oauth2/token'
  SOS_CLIENT_ID = ENV['SOS_CLIENT_ID']
  SOS_CLIENT_SECRET = ENV['SOS_CLIENT_SECRET']
  SOS_CODE = ENV['SOS_CODE']

  def self.connection
    sleep(0.5)
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.authorization :Bearer, SosToken.last&.access_token
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

  def self.customers
    paginator('customer')
  end

  def self.items
    paginator('item')
  end

  def self.single_page_resource(resource_name, retries = 0)
    response = connection.get(resource_name)
    response_data = response.body['data']
    unless response_data.present?
      if retries <= 3
        sleep(retries)
        response_data = single_page_resource(resource_name, retries + 1)
      else
        Airbrake.notify("SOS get #{resource_name} - MESSAGE: #{response.body['message']}")
      end
    end
    response_data
  end

  def self.locations
    single_page_resource('location')
  end

  def self.channels
    single_page_resource('channel')
  end

  def self.terms
    single_page_resource('terms')
  end

  def self.sales_reps
    single_page_resource('salesrep')
  end

  def self.create_sales_order(data)
    response = connection.post do |req|
      req.url "#{BASE_URL}/salesorder"
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end

    response.body['data']
  end

  # Need to get a new code every time this is done
  # get code via: "https://api.sosinventory.com/oauth2/authorize?response_type=code&client_id=#{SOS_CLIENT_ID}"
  # and then logging in to SOS. The code will be in the URL you are redirected to.
  def self.request_token
    data = [
      'grant_type=authorization_code',
      "client_id=#{SOS_CLIENT_ID}",
      "client_secret=#{SOS_CLIENT_SECRET}",
      "code=#{SOS_CODE}" # REPLACE THIS CONFIG VAR (see comment above)
    ].join('&')

    no_auth_connection = Faraday.new(url: AUTH_URL) do |faraday|
      faraday.request  :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end

    response = no_auth_connection.post do |req|
      req.url AUTH_URL
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = data
    end

    SosToken.last&.destroy
    SosToken.create(response.body)
  end

  def self.renew_token
    token = SosToken.last

    data = [
      'grant_type=refresh_token',
      "refresh_token=#{token.refresh_token}"
    ].join('&')

    response = SosClient.connection.post do |req|
      req.url AUTH_URL
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
      req.body = data
    end

    token.update_attributes(response.body)
    token
  end
end

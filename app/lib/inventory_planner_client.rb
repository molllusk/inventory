# frozen_string_literal: true

class InventoryPlannerClient
  BASE_URL = 'https://app.inventory-planner.com'
  IP_API_KEY = ENV['IP_API_KEY']
  IP_ACCOUNT = ENV['IP_ACCOUNT']

  SF_WAREHOUSE = 'c18098_49481991'
  SB_WAREHOUSE = 'c18098_7702609973'
  VB_WAREHOUSE = 'c18098_7702577205'

  IP_SHOPS = [SF_WAREHOUSE, SB_WAREHOUSE, VB_WAREHOUSE].freeze

  VEND_OUTLET_ID_BY_IP_SHOP = {
    SF_WAREHOUSE => '5e234f4e-8eed-11e0-8e09-4040f540b50a',
    SB_WAREHOUSE => '8d27bed3-060b-11e4-a0f5-b8ca3a64f8f4',
    VB_WAREHOUSE => '0adfd74a-153e-11e9-fa42-67b5781ba1fb'
  }.freeze

  SHOPIFY_OUTLET_ID_BY_IP_SHOP = {
    SF_WAREHOUSE => 3_265_917_026_389,
    SB_WAREHOUSE => 3_265_930_625_109,
    VB_WAREHOUSE => 3_265_924_825_173
  }.freeze

  SHOPIFY_LOCATION_BY_IP_SHOP = {
    SF_WAREHOUSE => 'Mollusk SF',
    SB_WAREHOUSE => 'Mollusk SB',
    VB_WAREHOUSE => 'Mollusk VB'
  }.freeze

  def self.vend_outlet_id(ip_shop)
    VEND_OUTLET_ID_BY_IP_SHOP[ip_shop]
  end

  def self.shopify_location(ip_shop)
    SHOPIFY_LOCATION_BY_IP_SHOP[ip_shop]
  end

  def self.connection
    sleep(0.5)
    Faraday.new(url: BASE_URL) do |faraday|
      faraday.headers[:authorization] = IP_API_KEY
      faraday.headers[:account] = IP_ACCOUNT
      faraday.request :url_encoded
      faraday.response :json
      faraday.adapter Faraday.default_adapter
    end
  end

  def self.open_store_purchase_orders
    params = {
      limit: 100,
      status_eqi: 'sent',
      vendor_eqi: 'mollusk',
      warehouse_ne: 'c18098_36225056853'
    }

    response = connection.get('api/v1/purchase-orders', params)
    response.body
  end

  def self.purchase_orders
    response = connection.get('api/v1/purchase-orders')
    response.body
  end

  def self.send_purchase_order(data)
    response = connection.post do |req|
      req.url 'api/v1/purchase-orders'
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end
    response.body
  end

  def self.cancel_purchase_order(inventory_planner_id)
    response = connection.patch do |req|
      req.url "api/v1/purchase-orders/#{inventory_planner_id}"
      req.headers['Content-Type'] = 'application/json'
      req.body = { 'purchase-order': { status: 'CANCELLED' } }.to_json
    end
    response.body
  end
end

# frozen_string_literal: true

class DailyOrder < ApplicationRecord
  belongs_to :daily_inventory_transfer
  has_many :orders, dependent: :destroy
  delegate :po_id, to: :daily_inventory_transfer

  scope :cancelled, lambda {
    where(cancelled: true)
  }

  scope :not_cancelled, lambda {
    where(cancelled: false)
  }

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop (San Francisco)<br />4500 Irving Street<br />San Francisco, CA 94122-1132',
    'Venice Beach' => 'Mollusk Surf Shop (Venice Beach)<br />1600 Pacific Avenue<br />Venice Beach, CA 90291-9998',
    'Santa Barbara' => 'Mollusk Surf Shop (Santa Barbara)<br />205-C Santa Barbara Street<br />Santa Barbara, CA 93101'
  }.freeze

  STREET_ADDRESSES = {
    'San Francisco' => '4500 Irving Street',
    'Venice Beach' => '1600 Pacific Avenue',
    'Santa Barbara' => '205-C Santa Barbara Street'
  }.freeze

  CITIES = {
    'San Francisco' => 'San Francisco',
    'Venice Beach' => 'Venice Beach',
    'Santa Barbara' => 'Santa Barbara'
  }.freeze

  ZIPS = {
    'San Francisco' => '94122-1132',
    'Venice Beach' => '90291-9998',
    'Santa Barbara' => '93101'
  }.freeze

  LOCATION_ID_BY_VEND_OUTLET_NAME = {
    'San Francisco' => 3265917026389,
    'Santa Barbara' => 3265930625109,
    'Venice Beach' => 3265924825173
  }

  PHONE_NUMBERS = {
    'San Francisco' => '415-564-6300',
    'Santa Barbara' => '805-568-0908',
    'Venice Beach' => '310-396-1969'
  }

  def to_pdf
    # create an instance of ActionView, so we can use the render method outside of a controller
    av = ActionView::Base.new
    av.view_paths = ActionController::Base.view_paths

    # need these in case your view constructs any links or references any helper methods.
    av.class_eval do
      include Rails.application.routes.url_helpers
      include ApplicationHelper
    end

    pdf_html = av.render template: 'daily_orders/po.html.erb', layout: nil, locals: { daily_order: self }

    HyPDF.htmltopdf(
      pdf_html,
      test: ENV['HYPDF_MODE'] == 'test'
    )[:pdf]
  end

  def to_csv
    headers = [
      :order_id,
      :first_name,
      :last_name,
      :email,
      :sku,
      :count,
      :address1,
      :address2,
      :city,
      :province_code,
      :country_code,
      :zipcode,
      :ship_after, # day the order is placed
      :ship_before, # 3 days after the day the order is placed
      :company,
      :draft,
      :note
    ]

    CSV.generate(headers: headers, write_headers: true) do |new_csv|
      orders.sort_by { |order| order.product.vend_datum.sort_key }.each do |order|
        new_csv << [
          display_po,
          'Mollusk',
          outlet_name,
          'joseph@mollusksurfshop.com',
          order.product.retail_shopify&.sku,
          order.quantity,
          street_address,
          nil,
          city,
          'CA',
          'US',
          zipcode,
          daily_inventory_transfer.date.strftime('%m/%d/%y'),
          daily_inventory_transfer.date.strftime('%m/%d/%y'),
          'Mollusk',
          nil,
          nil
        ]
      end
    end
  end

  def pdf_filename
    "mollusk_#{po_stem}_order_#{po_id}.pdf"
  end

  def csv_filename
    "mollusk_#{po_stem}_order_#{po_id}.csv"
  end

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def po?
    po_id.present?
  end

  def po_stem
    outlet_name.split.map(&:first).join.upcase
  end

  def display_po
    "#{po_stem} #{po_id}"
  end

  def shopify_order_url
    "https://mollusksurf.myshopify.com/admin/orders/#{shopify_order_id}" if shopify_order_id.present?
  end

  def shopify_shipping_address
    {
      first_name: 'Mollusk',
      last_name: outlet_name,
      address1: STREET_ADDRESSES[outlet_name],
      phone: PHONE_NUMBERS[outlet_name],
      city: CITIES[outlet_name],
      province: 'California',
      country: 'United States',
      zip: ZIPS[outlet_name]
    }
  end

  def shopify_customer_id
    LOCATION_ID_BY_VEND_OUTLET_NAME[outlet_name].to_s
  end

  def shopify_order_line_items
    orders.map(&:shopify_line_item)
  end

  def shopify_order_params
    line_items = shopify_order_line_items
    total_price = line_items.inject(0.0) { |sum, item| sum + item[:price].to_f }
    {
      order: {
        location_id: 36225056853,
        financial_status: 'paid',
        fulfillment_status: nil,
        taxable: false,
        note: "Order Number: #{display_po}",
        source_name: 'mollusk_app',
        total_tax: 0,
        total_price: 0,
        inventory_behaviour: 'decrement_ignoring_policy',
        customer: { id: shopify_customer_id },
        total_discounts: total_price,
        shipping_address: shopify_shipping_address,
        line_items: line_items
      }
    }
  end

  def post_to_shopify
    begin
      response = ShopifyClient.create_order(shopify_order_params)

      if response['order'].present?
        order_id = response['order']['id']
        update_attribute(:shopify_order_id, order_id) unless order_id.blank?
      else
        Airbrake.notify("Could not create Shopify Order for Daily Order: #{id} for #{outlet_name}: #{response['errors']}")
      end
    rescue StandardError
      Airbrake.notify("There was an ERROR creating Shopify Order for Daily Order: #{id} for #{outlet_name}")
    end
  end

  def create_consignment
    consignment = VendClient.create_consignment(self)
    update_attribute(:vend_consignment_id, consignment['id'])
    add_products_to_consignment
    send_consignment
  rescue StandardError
    Airbrake.notify("Could not create Consignment for Daily Order: #{id}")
  end

  def add_products_to_consignment
    orders.each do |order|
      VendClient.add_consignment_product(order)
    rescue StandardError
      Airbrake.notify("Could not add product to Consignment for Daily Order: #{id} / Product: #{order.product_id}")
    end
  end

  def send_consignment
    VendClient.update_consignment_status(vend_consignment_id, 'SENT')
  rescue StandardError
    Airbrake.notify("Could not SEND Consignment (#{vend_consignment_id}) for Daily Order: #{id}")
  end

  def cancel_consignment
    VendClient.update_consignment_status(vend_consignment_id, 'CANCELLED')
  rescue StandardError
    Airbrake.notify("Could not CANCEL Consignment (#{vend_consignment_id}) for Daily Order: #{id} for #{outlet_name}")
  end

  def cancel_shopify_order
    begin
      ShopifyClient.cancel_order(shopify_order_id)
    rescue StandardError
      Airbrake.notify("ERROR CANCELLING Shopify Order (#{shopify_order_id}) for Daily Order: #{id} for #{outlet_name}")
    end
  end

  def ship_to_address
    PO_ADDRESSES[outlet_name]
  end

  def street_address
    STREET_ADDRESSES[outlet_name]
  end

  def zipcode
    ZIPS[outlet_name]
  end

  def city
    CITIES[outlet_name]
  end

  def total_items
    orders.reduce(0) { |sum, order| sum + order.quantity }
  end

  def total_cost
    orders.reduce(0) { |sum, order| sum + order.total_cost }
  end

  def vend_consignment_url
    "https://mollusksurf.vendhq.com/consignment/#{vend_consignment_id}" if vend_consignment_id.present?
  end

  def cancel
    return if cancelled?
    orders.not_cancelled.each do |order|
      order.cancel
    end

    if orders.not_cancelled.count.zero?
      cancel_consignment unless vend_consignment_id.blank?
      cancel_shopify_order unless shopify_order_id.blank?
      update_attribute(:cancelled, true)
    end
  end
end

# == Schema Information
#
# Table name: daily_orders
#
#  id                          :bigint(8)        not null, primary key
#  cancelled                   :boolean          default(FALSE)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  daily_inventory_transfer_id :integer
#  outlet_id                   :string
#  shopify_order_id            :bigint(8)
#  vend_consignment_id         :string
#

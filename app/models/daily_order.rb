class DailyOrder < ApplicationRecord
  belongs_to :daily_inventory_transfer
  has_many :orders, dependent: :destroy
  delegate :po_id, to: :daily_inventory_transfer

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop (San Francisco)<br />4500 Irving Street<br />San Francisco, CA 94122-1132',
    'Venice Beach' => 'Mollusk Surf Shop (Venice Beach)<br />1600 Pacific Avenue<br />Venice Beach, CA 90291-9998',
    'Santa Barbara' => 'Mollusk Surf Shop (Santa Barbara)<br />121 E Yanonali Street<br />Santa Barbara, CA 93101'
  }

  STREET_ADDRESSES = {
    'San Francisco' => '4500 Irving Street',
    'Venice Beach' => '1600 Pacific Avenue',
    'Santa Barbara' => '121 E Yanonali Street'
  }

  CITIES = {
    'San Francisco' => 'San Francisco',
    'Venice Beach' => 'Venice Beach',
    'Santa Barbara' => 'Santa Barbara'
  }

  ZIPS = {
    'San Francisco' => '94122-1132',
    'Venice Beach' => '90291-9998',
    'Santa Barbara' => '93101'
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
          "Mollusk",
          outlet_name,
          "joseph@mollusksurfshop.com",
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

  def has_po?
    po_id.present?
  end

  def po_stem
    outlet_name.split.map(&:first).join.upcase
  end

  def display_po
    "#{po_stem} #{po_id}"
  end

  def create_consignment
    begin
      consignment = VendClient.create_consignment(self)
      update_attribute(:vend_consignment_id, consignment['id'])
      add_products_to_consignment
      send_consignment
    rescue
      Airbrake.notify("Could not create Consignment for Daily Order: #{id}")
    end
  end

  def add_products_to_consignment
    orders.each do |order|
      begin
        VendClient.add_consignment_product(order)
      rescue
        Airbrake.notify("Could not add product to Consignment for Daily Order: #{id} / Product: #{order.product_id}")
      end
    end
  end

  def send_consignment
    begin
      VendClient.send_consignment(vend_consignment_id)
    rescue
      Airbrake.notify("Could not SEND Consignment for Daily Order: #{id}")
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
end

# == Schema Information
#
# Table name: daily_orders
#
#  id                          :bigint(8)        not null, primary key
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  daily_inventory_transfer_id :integer
#  outlet_id                   :string
#  vend_consignment_id         :string
#

class DailyOrder < ApplicationRecord
  belongs_to :daily_inventory_transfer
  has_many :orders, dependent: :destroy
  delegate :po_id, to: :daily_inventory_transfer

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop (San Francisco)<br />4500 Irving Street<br />San Francisco, CA 94122-1132',
    'Venice Beach' => 'Mollusk Surf Shop (Venice Beach)<br />1600 Pacific Avenue<br />Venice Beach, CA 90291-9998',
    'Silver Lake' => 'Mollusk Surf Shop (Silver Lake)<br />3511 W Sunset Blvd<br />Los Angeles, CA 90026-9998'
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

  def pdf_filename
    "mollusk_#{po_stem}_order_#{po_id}.pdf"
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
      
      orders.each do |order|
        begin
          VendClient.add_consignment_product(order)
        rescue
          Airbrake.notify("Could not add product to Consignment for Daily Order: #{id} / Product: #{order.product_id}")
        end
      end
    rescue
      Airbrake.notify("Could not create Consignment for Daily Order: #{id}")
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

class DailyOrder < ApplicationRecord
  has_many :orders, dependent: :destroy

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop (San Francisco)<br />4500 Irving Street<br />San Francisco, CA 94122-1132',
    'Venice Beach' => 'Mollusk Surf Shop (Venice Beach)<br />1600 Pacific Avenue<br />Venice Beach, CA 90291-9998',
    'Silver Lake' => 'Mollusk Surf Shop (Silver Lake)<br />3511 W Sunset Blvd<br />Los Angeles, CA 90026-9998'
  }

  def self.last_po(outlet)
    where(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key(outlet)).maximum(:po_id).to_i
  end

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
    "Mollusk_Inventory_Transfer_PO_#{display_po.gsub(/\s+/,'_')}.pdf"
  end

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def po_stem
    outlet_name.split.map(&:first).join.upcase
  end

  def display_po
    "#{po_stem} #{po_id}"
  end

  def create_consignment

  end

  def ship_to_address
    PO_ADDRESSES[outlet_name]
  end

  def send_po
    ApplicationMailer.po_pdf(self).deliver
  end

  def total_items
    orders.reduce(0) { |sum, order| sum + order.quantity }
  end

  def total_cost
    orders.reduce(0) { |sum, order| sum + (order.quantity * order.cost) }
  end

  def vend_consignment_url
    "https://mollusksurf.vendhq.com/consignment/#{@daily_order.vend_consignment_id}" if vend_consignment_id.present?
  end
end

# == Schema Information
#
# Table name: daily_orders
#
#  id                  :bigint(8)        not null, primary key
#  date                :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  outlet_id           :string
#  po_id               :integer
#  qbo_id              :bigint(8)
#  vend_consignment_id :string
#

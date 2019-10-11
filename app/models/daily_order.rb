class DailyOrder < ApplicationRecord
  has_many :orders, dependent: :destroy

  PO_ADDRESSES = {
    'San Francisco' => 'Mollusk Surf Shop San Francisco<br />4500 Irving Street<br />San Francisco, CA 94122',
    'Venice Beach' => '',
    'Silver Lake' => ''
  }

  def self.last_po(outlet)
    where(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key(outlet)).maximum(:po_id).to_i
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
    # generate pdf
    # email it in attachment
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

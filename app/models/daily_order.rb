class DailyOrder < ApplicationRecord
  has_many :orders, dependent: :destroy
  
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

class VendConsignmentLocationCost < ApplicationRecord
  belongs_to :daily_vend_consignment, optional: true

  enum role: {
    receiver: 0,
    supplier: 1
  }

  scope :receiving, lambda {
    where(role: :receiver)
  }

  scope :supplying, lambda {
    where(role: :supplier)
  }

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end
end

# == Schema Information
#
# Table name: vend_consignment_location_costs
#
#  id                        :bigint(8)        not null, primary key
#  cost                      :float            default(0.0)
#  role                      :integer          default("receiver")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_vend_consignment_id :integer
#  outlet_id                 :string
#

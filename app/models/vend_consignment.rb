class VendConsignment < ApplicationRecord
  belongs_to :daily_vend_consignment, optional: true
end

# == Schema Information
#
# Table name: vend_consignments
#
#  id                        :bigint(8)        not null, primary key
#  cost                      :float            default(0.0)
#  received_at               :datetime
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_vend_consignment_id :integer
#  receiving_id              :string
#  supplying_id              :string
#  vend_consignment_id       :string
#

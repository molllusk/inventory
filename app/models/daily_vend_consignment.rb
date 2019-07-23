class DailyVendConsignment < ApplicationRecord
  has_many :vend_consignment_location_costs, dependent: :destroy
  has_many :vend_consignments, dependent: :destroy
end

# == Schema Information
#
# Table name: daily_vend_consignments
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

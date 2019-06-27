class DailyVendCost < ApplicationRecord
  has_many :vend_sales_costs, dependent: :destroy
  has_many :vend_sales_cost_sales, dependent: :destroy
end

# == Schema Information
#
# Table name: daily_vend_costs
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

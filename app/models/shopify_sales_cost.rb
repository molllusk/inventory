class ShopifySalesCost < ApplicationRecord
end

# == Schema Information
#
# Table name: shopify_sales_costs
#
#  id             :bigint(8)        not null, primary key
#  cost           :float            default(0.0)
#  date           :datetime
#  location_costs :json
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

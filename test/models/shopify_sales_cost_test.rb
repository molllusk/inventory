require 'test_helper'

class ShopifySalesCostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_sales_costs
#
#  id             :bigint(8)        not null, primary key
#  cost           :float            default(0.0)
#  date           :datetime
#  location_costs :json
#  store          :integer          default("retail")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

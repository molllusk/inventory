require 'test_helper'

class ShopifyPosSalesCostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_pos_sales_costs
#
#  id                         :bigint(8)        not null, primary key
#  cost                       :float            default(0.0)
#  location                   :bigint(8)
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  daily_shopify_pos_costs_id :integer
#

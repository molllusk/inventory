# frozen_string_literal: true

require 'test_helper'

class ShopifySalesCostOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_sales_cost_orders
#
#  id                    :bigint(8)        not null, primary key
#  closed_at             :datetime
#  cost                  :float            default(0.0)
#  location_costs        :json
#  name                  :string
#  store                 :integer          default("retail")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  order_id              :bigint(8)
#  shopify_sales_cost_id :integer
#

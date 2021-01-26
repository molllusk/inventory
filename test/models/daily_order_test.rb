# frozen_string_literal: true

require 'test_helper'

class DailyOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: daily_orders
#
#  id                          :bigint(8)        not null, primary key
#  cancelled                   :boolean          default(FALSE)
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  daily_inventory_transfer_id :integer
#  inventory_planner_id        :integer
#  outlet_id                   :string
#  shopify_order_id            :bigint(8)
#  vend_consignment_id         :string
#

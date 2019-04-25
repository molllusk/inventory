# == Schema Information
#
# Table name: fluid_inventory_thresholds
#
#  id           :bigint(8)        not null, primary key
#  product_type :bigint(8)
#  threshold    :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

require 'test_helper'

class FluidInventoryThresholdTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

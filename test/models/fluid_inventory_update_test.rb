# frozen_string_literal: true

# == Schema Information
#
# Table name: fluid_inventory_updates
#
#  id                  :bigint(8)        not null, primary key
#  adjustment          :integer
#  new_retail_qty      :integer
#  new_wholesale_qty   :integer
#  prior_retail_qty    :integer
#  prior_wholesale_qty :integer
#  threshold           :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  product_id          :integer
#

require 'test_helper'

class FluidInventoryUpdateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

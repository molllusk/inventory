require 'test_helper'

class OrderInventoryUpdateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: order_inventory_updates
#
#  id            :bigint(8)        not null, primary key
#  new_jam_qty   :integer
#  prior_jam_qty :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  order_id      :integer
#

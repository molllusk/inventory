require 'test_helper'

class WholesaleOrderItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: wholesale_order_items
#
#  id                 :bigint(8)        not null, primary key
#  department         :string
#  item_name          :string
#  quantity_ordered   :integer
#  unit_price         :float
#  sos_item_id        :bigint(8)
#  wholesale_order_id :integer
#
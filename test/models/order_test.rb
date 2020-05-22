# frozen_string_literal: true

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: orders
#
#  id             :bigint(8)        not null, primary key
#  cost           :float
#  quantity       :integer
#  sent_orders    :integer          default(0)
#  threshold      :integer
#  vend_qty       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  daily_order_id :integer
#  product_id     :integer
#

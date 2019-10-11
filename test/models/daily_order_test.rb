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
#  id                  :bigint(8)        not null, primary key
#  date                :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  outlet_id           :string
#  po_id               :string
#  qbo_id              :bigint(8)
#  vend_consignment_id :string
#

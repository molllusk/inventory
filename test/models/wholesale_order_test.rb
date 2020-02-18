require 'test_helper'

class WholesaleOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: wholesale_orders
#
#  id              :bigint(8)        not null, primary key
#  cancel_date     :datetime
#  customer        :string
#  customer_po     :string
#  location        :string
#  ref_number      :string
#  sos_total       :float
#  start_ship      :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  sos_customer_id :bigint(8)
#  sos_id          :integer
#

# frozen_string_literal: true

require 'test_helper'

class VendSalesCostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: vend_sales_costs
#
#  id                 :bigint(8)        not null, primary key
#  cost               :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  daily_vend_cost_id :integer
#  outlet_id          :string
#

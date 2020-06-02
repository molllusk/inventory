# frozen_string_literal: true

require 'test_helper'

class VendConsignmentLocationCostTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: vend_consignment_location_costs
#
#  id                        :bigint(8)        not null, primary key
#  cost                      :float            default(0.0)
#  role                      :integer          default("receiver")
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_vend_consignment_id :integer
#  outlet_id                 :string
#

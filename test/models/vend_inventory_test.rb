# frozen_string_literal: true

require 'test_helper'

class VendInventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: vend_inventories
#
#  id            :bigint(8)        not null, primary key
#  inventory     :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  outlet_id     :string
#  vend_datum_id :integer
#

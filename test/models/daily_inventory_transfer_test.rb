# frozen_string_literal: true

require 'test_helper'

class DailyInventoryTransferTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: daily_inventory_transfers
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  po_id      :integer
#  qbo_id     :integer
#

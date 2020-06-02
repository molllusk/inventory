# frozen_string_literal: true

require 'test_helper'

class DailyVendConsignmentTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: daily_vend_consignments
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  qbo_id     :bigint(8)
#

require 'test_helper'

class QboTokenTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: qbo_tokens
#
#  id            :bigint(8)        not null, primary key
#  refresh_token :string
#  token         :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  realm_id      :string
#

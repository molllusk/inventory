# frozen_string_literal: true

require 'test_helper'

class DailyInventoryTransfersControllerTest < ActionDispatch::IntegrationTest
  test 'should get date:datetime' do
    get daily_inventory_transfers_date: datetime_url
    assert_response :success
  end

  test 'should get qbo_id:integer' do
    get daily_inventory_transfers_qbo_id: integer_url
    assert_response :success
  end
end

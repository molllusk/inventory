# frozen_string_literal: true

require 'test_helper'

class VendSalesReceiptTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: vend_sales_receipts
#
#  id                     :bigint(8)        not null, primary key
#  cash_or_check_payments :float            default(0.0)
#  credit_payments        :float            default(0.0)
#  discount               :float            default(0.0)
#  discount_sales         :float            default(0.0)
#  gift_card_payments     :float            default(0.0)
#  gift_card_sales        :float            default(0.0)
#  product_sales          :float            default(0.0)
#  sales_tax              :float            default(0.0)
#  shipping               :float            default(0.0)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  daily_vend_sale_id     :integer
#  outlet_id              :string
#  qbo_id                 :bigint(8)
#

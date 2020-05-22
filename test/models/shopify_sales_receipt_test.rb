# frozen_string_literal: true

# == Schema Information
#
# Table name: shopify_sales_receipts
#
#  id                 :bigint(8)        not null, primary key
#  date               :datetime
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  gift_card_sales    :float            default(0.0)
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  store              :integer          default("retail")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  qbo_id             :bigint(8)
#

require 'test_helper'

class ShopifySalesReceiptTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

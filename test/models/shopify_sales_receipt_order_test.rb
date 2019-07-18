require 'test_helper'

class ShopifySalesReceiptOrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_sales_receipt_orders
#
#  id                       :bigint(8)        not null, primary key
#  closed_at                :datetime
#  discount                 :float            default(0.0)
#  gift_card_payments       :float            default(0.0)
#  gift_card_sales          :float            default(0.0)
#  name                     :string
#  paypal_payments          :float            default(0.0)
#  product_sales            :float            default(0.0)
#  sales_tax                :float            default(0.0)
#  shipping                 :float            default(0.0)
#  shopify_payments         :float            default(0.0)
#  store                    :integer          default("retail")
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  order_id                 :bigint(8)
#  shopify_sales_receipt_id :integer
#

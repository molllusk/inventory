require 'test_helper'

class ShopifyPosSalesReceiptSaleTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_pos_sales_receipt_sales
#
#  id                        :bigint(8)        not null, primary key
#  cash_payments             :float            default(0.0)
#  credit_payments           :float            default(0.0)
#  discount                  :float            default(0.0)
#  discount_sales            :float            default(0.0)
#  gift_card_payments        :float            default(0.0)
#  gift_card_sales           :float            default(0.0)
#  location                  :bigint(8)
#  name                      :string
#  product_sales             :float            default(0.0)
#  rentals                   :float            default(0.0)
#  sale_at                   :datetime
#  sales_tax                 :float            default(0.0)
#  shipping                  :float            default(0.0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_shopify_pos_sale_id :integer
#  order_id                  :bigint(8)
#

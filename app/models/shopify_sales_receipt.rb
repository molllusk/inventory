class ShopifySalesReceipt < ApplicationRecord
  has_many :shopify_sales_receipt_orders, dependent: :destroy

  def sum_check
    product_sales + gift_card_sales + sales_tax + shipping - discount - shopify_payments - paypal_payments - gift_card_payments
  end

  def qbo_params

  end

  def post_to_qbo

  end
end

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
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

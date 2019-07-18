class ShopifySalesReceiptOrder < ApplicationRecord
  belongs_to :shopify_sales_receipt, optional: true

  def sum_check
    product_sales.round(2) + gift_card_sales.round(2) + sales_tax.round(2) + shipping.round(2) - discount.round(2) - shopify_payments.round(2) - paypal_payments.round(2) - gift_card_payments.round(2)
  end
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
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  order_id                 :bigint(8)
#  shopify_sales_receipt_id :integer
#

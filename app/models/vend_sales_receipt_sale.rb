class VendSalesReceiptSale < ApplicationRecord
  belongs_to :daily_vend_sale, optional: true

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def sum_check
    product_sales + gift_card_sales + sales_tax + shipping + discount_sales - discount - credit_payments - cash_or_check_payments - gift_card_payments
  end
end

# == Schema Information
#
# Table name: vend_sales_receipt_sales
#
#  id                     :bigint(8)        not null, primary key
#  cash_or_check_payments :float            default(0.0)
#  credit_payments        :float            default(0.0)
#  discount               :float            default(0.0)
#  discount_sales         :float            default(0.0)
#  gift_card_payments     :float            default(0.0)
#  gift_card_sales        :float            default(0.0)
#  product_sales          :float            default(0.0)
#  receipt_number         :integer
#  sale_at                :datetime
#  sales_tax              :float            default(0.0)
#  shipping               :float            default(0.0)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  daily_vend_sale_id     :integer
#  outlet_id              :string
#  sale_id                :string
#

# frozen_string_literal: true

class VendSalesReceipt < ApplicationRecord
  belongs_to :daily_vend_sale, optional: true

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def credits
    discount.round(2) + credit_payments.round(2) + cash_or_check_payments.round(2) + gift_card_payments.round(2)
  end

  def debits
    product_sales.round(2) + gift_card_sales.round(2) + sales_tax.round(2) + shipping.round(2) + discount_sales.round(2)
  end

  def sum_check
    credits - debits
  end
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

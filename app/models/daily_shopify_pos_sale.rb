# frozen_string_literal: true

class DailyShopifyPosSale < ApplicationRecord
  has_many :shopify_pos_sales_receipts, dependent: :destroy
  has_many :shopify_pos_sales_receipt_sales, dependent: :destroy
  has_one :shopify_pos_sales_tax, dependent: :destroy

  def sales_receipt_params(receipt)
    {
      txn_date: date,
      customer_ref: Qbo.base_ref(Qbo::CUSTOMER_ID_BY_OUTLET[receipt.outlet_name]),
      deposit_to_account_ref: Qbo.base_ref(3544) # 12001 Undeposited Funds
    }
  end

  def sales_receipt_line_item_details(receipt)
    [
      {
        item_id: '172114', # Taxable Retail Sales
        amount: receipt.product_sales,
        description: 'Taxable Retail Sales'
      },
      {
        item_id: '172117', # Gift Certificates
        amount: receipt.gift_card_sales,
        description: 'Gift Certificate Sales'
      },
      {
        item_id: '173274', # Shipping-Non Taxable
        amount: receipt.shipping,
        description: 'Shipping-Non Taxable'
      },
      {
        item_id: Qbo::TAX_ITEM_ID_BY_OUTLET[receipt.outlet_name], # Outlet Name (sales tax)
        amount: receipt.sales_tax,
        description: "#{receipt.outlet_name} Sales Tax"
      },
      {
        item_id: '181577', # Discount
        amount: receipt.discount_sales - receipt.discount,
        description: 'Discount'
      },
      {
        item_id: '181527', # Cash/Check Payment - Retail
        amount: -receipt.cash_payments,
        description: 'Cash or Check Payments'
      },
      {
        item_id: Qbo::CREDIT_CARD_PAYMENT_ID_BY_OUTLET[receipt.outlet_name], # Paypal Payment
        amount: -receipt.credit_payments,
        description: "Credit Card Payment - #{receipt.outlet_name}"
      },
      {
        item_id: '172117', # Gift Certificates
        amount: -receipt.gift_card_payments,
        description: 'Gift Certificate payments'
      },
      {
        item_id: '177181', # Over/Short
        amount: receipt.sum_check,
        description: 'Over/Short'
      }
    ]
  end

  def post_to_qbo
    if shopify_pos_sales_receipt_sales.present?
      sales_receipts.each do |receipt_pair|
        qbo = Qbo.create_sales_receipt(receipt_pair.last)
        receipt_pair.first.update_attribute(:qbo_id, qbo.id) unless qbo.blank?
      end
    end
  end

  def sales_receipts
    receipts = []

    shopify_pos_sales_receipts.each do |receipt|
      sales_receipt = Qbo.sales_receipt(sales_receipt_params(receipt))

      sales_receipt_line_item_details(receipt).each do |details|
        line_item_params = {
          amount: details[:amount],
          description: details[:description]
        }

        sales_receipt_line_detail = {
          unit_price: details[:amount],
          quantity: 1,
          item_ref: Qbo.base_ref(details[:item_id]),
          class_ref: Qbo.base_ref(Qbo::CLASS_ID_BY_OUTLET[receipt.outlet_name])
        }

        line_item = Qbo.sales_receipt_line_item(line_item_params, sales_receipt_line_detail)

        sales_receipt.line_items << line_item
      end

      receipts << [receipt, sales_receipt]
    end
    receipts
  end
end

# == Schema Information
#
# Table name: daily_shopify_pos_sales
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

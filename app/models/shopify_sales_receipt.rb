class ShopifySalesReceipt < ApplicationRecord
  has_many :shopify_sales_receipt_orders, dependent: :destroy

  enum store: {
    retail: 0,
    wholesale: 1
  }

  scope :retail, lambda {
    where(store: :retail)
  }

  scope :wholesale, lambda {
    where(store: :wholesale)
  }

  def sum_check
    product_sales.round(2) + gift_card_sales.round(2) + sales_tax.round(2) + shipping.round(2) - discount.round(2) - shopify_payments.round(2) - paypal_payments.round(2) - gift_card_payments.round(2)
  end

  def sales_receipt_params
    {
      txn_date: date,
      customer_ref: Qbo.base_ref(Qbo::SHOPIFY_CUSTOMER_ID),
      deposit_to_account_ref: Qbo.base_ref(3544) # 12001 Undeposited Funds
    }
  end

  def sales_receipt_line_item_details
    [
      {
        item_id: '172114', # Taxable Retail Sales
        amount: product_sales,
        description: 'Taxable Retail Sales'
      },
      {
        item_id: '172117', # Gift Certificates
        amount: gift_card_sales,
        description: 'Gift Certificate Sales'
      },
      {
        item_id: '173274', # Shipping-Non Taxable
        amount: shipping,
        description: 'Shipping-Non Taxable'
      },
      {
        item_id: '172116', # San Francisco (sales tax)
        amount: sales_tax,
        description: 'San Francisco Sales Tax'
      },
      {
        item_id: '181577', # Discount
        amount: -discount,
        description: 'Discount'
      },
      {
        item_id: '174882', # Shopify Payments
        amount: -shopify_payments,
        description: 'Credit Payments'
      },
      {
        item_id: '175037', # Paypal Payment
        amount: -paypal_payments,
        description: 'Paypal Payments',
      },
      {
        item_id: '172117', # Gift Certificates
        amount: -gift_card_payments,
        description: 'Gift Certificate payments',
      },
      {
        item_id: '177181', # Over/Short
        amount: sum_check.abs,
        description: 'Over/Short'
      }
    ]
  end

  def post_to_qbo
    Qbo.create_sales_receipt(sales_receipt)
  end

  def sales_receipt
    sales_receipt = Qbo.sales_receipt(sales_receipt_params)

    sales_receipt_line_item_details.each do |details|
      line_item_params = {
        amount: details[:amount],
        description: details[:description]
      }

      sales_receipt_line_detail = {
        unit_price: details[:amount],
        quantity: 1,
        item_ref: Qbo.base_ref(details[:item_id]),
        class_ref: Qbo.base_ref(Qbo::MOLLUSK_WEST_CLASS),
      }

      line_item = Qbo.sales_receipt_line_item(line_item_params, sales_receipt_line_detail)

      sales_receipt.line_items << line_item
    end

    sales_receipt
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
#  store              :integer          default("retail")
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

class DailyVendSale < ApplicationRecord
  has_many :vend_sales_receipts, dependent: :destroy
  has_many :vend_sales_receipt_sales, dependent: :destroy

  TAX_ITEM_ID_BY_OUTLET = {
    'San Francisco' => '172116',
    'Silver Lake' => '174884',
    'Venice Beach' => '181525'
  }

  CREDIT_CARD_PAYMENT_ID_BY_OUTLET = {
    'San Francisco' => '181526',
    'Silver Lake' => '181528',
    'Venice Beach' => '181529'
  }

  CUSTOMER_ID_BY_OUTLET = {
    'San Francisco' => Qbo::SF_CUSTOMER_ID,
    'Silver Lake' => Qbo::SILVER_LAKE_CUSTOMER_ID,
    'Venice Beach' => Qbo::VENICE_CUSTOMER_ID
  }

  CLASS_ID_BY_OUTLET = {
    'San Francisco' => Qbo::SAN_FRAN_CLASS,
    'Silver Lake' => Qbo::SILVER_LAKE_CLASS,
    'Venice Beach' => Qbo::VENICE_BEACH_CLASS
  }

  def sales_receipt_params(receipt)
    {
      txn_date: date,
      customer_ref: Qbo.base_ref(CUSTOMER_ID_BY_OUTLET[receipt.outlet_name]),
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
        item_id: TAX_ITEM_ID_BY_OUTLET[receipt.outlet_name], # Outlet Name (sales tax)
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
        amount: -receipt.cash_or_check_payments,
        description: 'Cash or Check Payments'
      },
      {
        item_id: CREDIT_CARD_PAYMENT_ID_BY_OUTLET[receipt.outlet_name], # Paypal Payment
        amount: -receipt.credit_payments,
        description: "Credit Card Payment - #{receipt.outlet_name}",
      },
      {
        item_id: '172117', # Gift Certificates
        amount: -receipt.gift_card_payments,
        description: 'Gift Certificate payments',
      },
      {
        item_id: '177181', # Over/Short
        amount: receipt.sum_check.abs,
        description: 'Over/Short'
      }
    ]
  end

  def post_to_qbo
    sales_receipts.each do |sales_receipt|
      Qbo.create_sales_receipt(sales_receipt)
    end
  end

  def sales_receipts
    receipts = []

    vend_sales_receipts.each do |receipt|
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
          class_ref: Qbo.base_ref(CLASS_ID_BY_OUTLET[receipt.outlet_name]),
        }

        line_item = Qbo.sales_receipt_line_item(line_item_params, sales_receipt_line_detail)

        sales_receipt.line_items << line_item
      end

      receipts << sales_receipt
    end
    receipts
  end
end

# == Schema Information
#
# Table name: daily_vend_sales
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

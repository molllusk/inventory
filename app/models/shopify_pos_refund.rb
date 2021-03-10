# frozen_string_literal: true

class ShopifyPosRefund < ApplicationRecord
  belongs_to :shopify_refund, optional: true

  enum location_id: {
    # retail site
    'San Francisco' => 49481991,
    'Santa Barbara' => 7_702_609_973,
    'Venice Beach' => 7_702_577_205
  }

  def journal_line_item_details
    [
      {
        account_id: '3481', # 40003 Sales:Taxable Sales
        amount: product_sales,
        description: 'Returned Product Sales',
        posting_type: 'Debit'
      },
      {
        account_id: '3549', # 25500 *Sales Tax Payable
        amount: sales_tax,
        description: 'Sales Tax Payable',
        posting_type: 'Debit'
      },
      {
        account_id: '3557', # 43000 Freight Income
        amount: refunded_shipping,
        description: 'Refunded Shipping',
        posting_type: 'Debit'
      },
      {
        account_id: '3454', # 43000 Sales Discounts
        amount: discount,
        description: 'Discounts',
        posting_type: 'Credit'
      },
      {
        account_id: '3454', # 43000 Sales Discounts
        amount: arbitrary_discount,
        description: 'Arbitrary Discounts',
        posting_type: 'Debit'
      },
      {
        account_id: '3611', # 12010 Credit Card Clearing
        amount: shopify_payments,
        description: 'Credit refunds',
        posting_type: 'Credit'
      },
      {
        account_id: '3487', # 10025 PayPal
        amount: paypal_payments,
        description: 'Paypal refunds',
        posting_type: 'Credit'
      },
      {
        account_id: '3504', # 22050 Gift Certificates Outstanding
        amount: gift_card_payments,
        description: 'Gift certificate refunds',
        posting_type: 'Credit'
      },
      {
        account_id: '3557', # 43000 Freight Income
        amount: shipping_clean,
        description: 'Return Shipping Fees',
        posting_type: 'Credit'
      },
      {
        account_id: '3476', # 50000 Cost of Goods Sold
        amount: cost,
        description: 'Returned COGS',
        posting_type: 'Credit'
      },
      {
        account_id: Qbo::PETTY_CASH_ID_BY_OUTLET[location_id],
        amount: cash_payments,
        description: 'Petty Cash by Location',
        posting_type: 'Credit'
      },
      {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET[location_id],
        amount: cost,
        description: 'Costs for Location (POS)',
        posting_type: 'Debit'
      }
    ]
  end

  # kind of hacky workaround for an edgecase where the shipping calc is just shy of 0 due to some significant digit thing
  def shipping_clean
    shipping > -0.01 && shipping.negative? ? 0 : shipping
  end

  def journal_entry_line_items
    journal_line_item_details.map do |details|
      line_item_params = {
        amount: details[:amount],
        description: details[:description]
      }

      journal_entry_line_detail = {
        account_ref: Qbo.base_ref(details[:account_id]),
        class_ref: Qbo.base_ref(Qbo::CLASS_ID_BY_OUTLET[location_id]),
        posting_type: details[:posting_type]
      }

      Qbo.journal_entry_line_item(line_item_params, journal_entry_line_detail)
    end
  end
end

# == Schema Information
#
# Table name: shopify_pos_refunds
#
#  id                 :bigint(8)        not null, primary key
#  arbitrary_discount :float            default(0.0)
#  cash_payments      :float            default(0.0)
#  cost               :float            default(0.0)
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  refunded_shipping  :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  total_payments     :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  location_id        :bigint(8)
#  shopify_refund_id  :integer
#

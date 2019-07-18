class ShopifyRefund < ApplicationRecord
  has_many :shopify_refund_orders, dependent: :destroy

  def location_cost(location)
    location_id = ShopifyInventory::locations[location].to_s
    location_costs.present? ? (location_costs[location_id] || 0) : 0
  end

  def journal_entry_params
    {
      txn_date: date
    }
  end

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
        amount: discount + arbitrary_discount,
        description: 'Discounts',
        posting_type: 'Credit'
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
        amount: shipping,
        description: 'Return Shipping Fees',
        posting_type: 'Credit'
      },
      {
        account_id: '3476', # 50000 Cost of Goods Sold
        amount: cost,
        description: 'Returned COGS',
        posting_type: 'Debit'
      },
      # {
      #   account_id: '3491', # 11000 Inventory Asset
      #   amount: location_cost('Jam Warehouse Retail').to_f,
      #   description: 'Costs by Jam Location',
      #   posting_type: 'Credit'
      # },
      {
        account_id: '3617', # 11001 Inventory Asset - San Francisco
        amount: location_costs.values.reduce(0) { |cost, sum| cost.to_f + sum.to_f },
        description: 'Costs by SF Location (includes cost of returns from all locations)',
        posting_type: 'Credit'
      }
    ]
  end

  def post_to_qbo
    Qbo.create_journal_entry(journal_entry)
  end

  def journal_entry
    journal_entry = Qbo.journal_entry(journal_entry_params)

    journal_line_item_details.each do |details|
      line_item_params = {
        amount: details[:amount],
        description: details[:description]
      }

      journal_entry_line_detail = {
        account_ref: Qbo.base_ref(details[:account_id]),
        class_ref: Qbo.base_ref(Qbo::MOLLUSK_WEST_CLASS),
        posting_type: details[:posting_type]
      }

      line_item = Qbo.journal_entry_line_item(line_item_params, journal_entry_line_detail)

      journal_entry.line_items << line_item
    end

    journal_entry
  end
end

# == Schema Information
#
# Table name: shopify_refunds
#
#  id                 :bigint(8)        not null, primary key
#  arbitrary_discount :float            default(0.0)
#  cost               :float            default(0.0)
#  date               :datetime
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  location_costs     :json
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  refunded_shipping  :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  total_payments     :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

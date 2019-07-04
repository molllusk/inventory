class ShopifySalesCost < ApplicationRecord
  has_many :shopify_sales_cost_orders, dependent: :destroy

  def journal_entry_params
    {
      txn_date: date
    }
  end

  def journal_line_item_details
    [
      {
        account_id: 50000,
        amount: cost,
        description: 'Total Cost of Sales'
      },
      {
        account_id: 11001,
        amount: jam_cost,
        description: 'Total Cost of Sales'
      },
      {
        account_id: 11001,
        amount: sf_cost,
        description: 'Total Cost of Sales'
      }
    ]
  end

  def jam_cost
    location_costs.present? ? (location_costs[ShopifyInventory::locations['Jam Warehouse Retail']] || 0.0) : 0.0
  end

  def sf_cost
    location_costs.present? ? (location_costs[ShopifyInventory::locations['Mollusk SF']] || 0.0) : 0.0
  end

  def post_to_qbo

  end

  def journal_entry
    journal_entry = Qbo.journal_entry(journal_entry_params)

    journal_line_item_details.each do |details|
      line_item = Qbo.journal_entry_line_item({ amount: details[:amount], description: details[:description] })
      line_item.journal_entry_line_detail.account_ref = Qbo.account_ref(details: account_id)
      line_item.journal_entry_line_detail.posting_type = account_id == 11001 ? 'Credit' : 'Debit'
      journal_entry.line_items << line_item
    end

    journal_entry
  end
end

# == Schema Information
#
# Table name: shopify_sales_costs
#
#  id             :bigint(8)        not null, primary key
#  cost           :float            default(0.0)
#  date           :datetime
#  location_costs :json
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#


  # - “50000 Cost of Goods Sold” - COGS value passed as “DEBITS”
  # - “11001 Inventory Asset - San Francisco” - SF COGS value passed as “CREDITS”
  # - “11000 Inventory Asset” - Jam COGS value passed as “CREDITS”
class ShopifySalesCost < ApplicationRecord
  has_many :shopify_sales_cost_orders, dependent: :destroy

  def location_cost(location)
    location_id = ShopifyInventory::locations[location]
    location_costs.present? ? (location_costs[location_id] || 0.0) : 0.0
  end

  def journal_entry_params
    {
      txn_date: date
    }
  end

  def journal_line_item_details
    [
      {
        account_id: "50000",
        amount: cost,
        description: 'Total Cost of Sales',
        posting_type: 'Debit'
      },
      {
        account_id: "11001",
        amount: location_cost('Jam Warehouse Retail'),
        description: 'Total Cost of Sales',
        posting_type: 'Credit'
      },
      {
        account_id: "11001",
        amount: location_cost('Mollusk SF'),
        description: 'Total Cost of Sales',
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
      line_item = Qbo.journal_entry_line_item({ amount: details[:amount], description: details[:description] })
      line_item.journal_entry_line_detail.account_ref = Qbo.account_ref(details[:account_id])
      line_item.journal_entry_line_detail.posting_type = details[:posting_type]
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
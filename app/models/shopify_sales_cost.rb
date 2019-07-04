class ShopifySalesCost < ApplicationRecord
  has_many :shopify_sales_cost_orders, dependent: :destroy

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
        account_id: '3476', # 50000 Cost of Goods Sold
        amount: cost,
        description: 'Total Cost of Sales Shopify',
        posting_type: 'Debit'
      },
      {
        account_id: '3491', # 11000 Inventory Asset
        amount: location_cost('Jam Warehouse Retail').to_f,
        description: 'Total Cost of Sales Shopify',
        posting_type: 'Credit'
      },
      {
        account_id: '3617', # 11001 Inventory Asset - San Francisco
        amount: location_cost('Mollusk SF').to_f,
        description: 'Total Cost of Sales Shopify',
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
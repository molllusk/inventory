# frozen_string_literal: true

class ShopifySalesCost < ApplicationRecord
  has_many :shopify_sales_cost_orders, dependent: :destroy

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

  def location_cost(location)
    location_id = ShopifyInventory.locations[location].to_s
    location_costs.present? ? (location_costs[location_id] || 0) : 0
  end

  def journal_entry_params
    {
      txn_date: date,
      doc_number: "APP-SC-#{id}"
    }
  end

  def journal_line_item_details
    send("#{store}_journal_line_item_details".to_sym)
  end

  def wholesale_journal_line_item_details
    [
      {
        account_id: '3562', # 51000 – Wholesale
        amount: cost,
        description: 'Total Cost of Sales Wholesale Shopify',
        posting_type: 'Debit'
      },
      {
        account_id: '3660', # 11004 Inventory Asset - Postworks
        amount: location_cost('Postworks ATS').to_f,
        description: 'Total Cost of Sales Wholesale Shopify - Postworks ATS',
        posting_type: 'Credit'
      },
      {
        account_id: '3652', # 11137 Finished Goods - Shopify
        amount: location_cost('Jam Warehouse Wholesale').to_f,
        description: 'Total Cost of Sales Wholesale Shopify - Jam Warehouse',
        posting_type: 'Credit'
      }
    ]
  end

  def retail_journal_line_item_details
    [
      {
        account_id: '3476', # 50000 Cost of Goods Sold
        amount: cost,
        description: 'Total Cost of Sales Shopify',
        posting_type: 'Debit'
      },
      {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET['San Francisco'],
        amount: location_cost('Mollusk SF').to_f,
        description: 'Total Cost of Sales Shopify - San Francisco',
        posting_type: 'Credit'
      },
      {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET['Santa Barbara'],
        amount: location_cost('Mollusk SB').to_f,
        description: 'Total Cost of Sales Shopify - Santa Barbara',
        posting_type: 'Credit'
      },
      {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET['Venice Beach'],
        amount: location_cost('Mollusk VB').to_f,
        description: 'Total Cost of Sales Shopify - Venice Beach',
        posting_type: 'Credit'
      },
      {
        account_id: '3660', # 11004 Inventory Asset - Postworks
        amount: location_cost('Postworks').to_f,
        description: 'Total Cost of Sales Shopify - Postworks',
        posting_type: 'Credit'
      },
      {
        account_id: '3652', # 11137 Finished Goods - Shopify
        amount: location_cost('Jam Warehouse Retail').to_f,
        description: 'Total Cost of Sales Shopify - Jam Warehouse',
        posting_type: 'Credit'
      }
    ]
  end

  def post_to_qbo
    return unless shopify_sales_cost_orders.present?

    qbo = Qbo.create_journal_entry(journal_entry)
    update_attribute(:qbo_id, qbo.id) unless qbo.blank?
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
#  store          :integer          default("retail")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  qbo_id         :bigint(8)
#

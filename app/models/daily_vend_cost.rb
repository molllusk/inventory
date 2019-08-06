class DailyVendCost < ApplicationRecord
  has_many :vend_sales_costs, dependent: :destroy
  has_many :vend_sales_cost_sales, dependent: :destroy

  ACCOUNT_ID_BY_OUTLET = {
    'San Francisco' => '3617', # 11001 Inventory Asset - San Francisco
    'Silver Lake' => '3618', # 11002 Inventory Asset - Silver Lake
    'Venice Beach' => '3626' # 11003 Inventory Asset - Venice Beach
  }

  CLASS_ID_BY_OUTLET = {
    'San Francisco' => Qbo::SAN_FRAN_CLASS,
    'Silver Lake' => Qbo::SILVER_LAKE_CLASS,
    'Venice Beach' => Qbo::VENICE_BEACH_CLASS
  }

  def journal_entry_params
    {
      txn_date: date,
      doc_number: "APP-VC-#{id}"
    }
  end

  def journal_line_item_details
    details = []
    vend_sales_costs.each do |sales_cost|
      outlet = sales_cost.outlet_id

      details << {
        account_id: '3476', # cost of goods sold
        amount: sales_cost.cost,
        description: 'Total Cost of Sales Vend',
        posting_type: 'Debit',
        class_id: CLASS_ID_BY_OUTLET[sales_cost.outlet_name]
      }
    
      details << {
        account_id: ACCOUNT_ID_BY_OUTLET[sales_cost.outlet_name], # Location specific Inventory Asset
        amount: sales_cost.cost,
        description: 'Total Cost of Sales Vend',
        posting_type: 'Credit',
        class_id: CLASS_ID_BY_OUTLET[sales_cost.outlet_name]
      }
    end
    details
  end

  def post_to_qbo
    if vend_sales_cost_sales.present?
      qbo = Qbo.create_journal_entry(journal_entry)
      update_attribute(:qbo_id, qbo.id) unless qbo.blank?
    end
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
        class_ref: Qbo.base_ref(details[:class_id]),
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
# Table name: daily_vend_costs
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  qbo_id     :bigint(8)
#

class DailyVendConsignment < ApplicationRecord
  has_many :vend_consignment_location_costs, dependent: :destroy
  has_many :vend_consignments, dependent: :destroy

  def journal_entry_params
    {
      txn_date: date,
      doc_number: "APP-VIT-#{id}"
    }
  end

  def journal_line_item_details
    details = []
    vend_consignment_location_costs.each do |location_cost|
      details << {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET[location_cost.outlet_name],
        amount: location_cost.cost,
        description: "Inventory transfer / Consignment cost for #{location_cost.role}: #{location_cost.outlet_name}",
        posting_type: location_cost.role == 'receiver' ? 'Debit' : 'Credit',
        class_id: Qbo::CLASS_ID_BY_OUTLET[location_cost.outlet_name]
      }
    end
    details
  end

  def post_to_qbo
    if vend_consignment_location_costs.present?
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
# Table name: daily_vend_consignments
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  qbo_id     :bigint(8)
#

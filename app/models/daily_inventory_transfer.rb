# frozen_string_literal: true

class DailyInventoryTransfer < ApplicationRecord
  has_many :daily_orders, dependent: :destroy

  scope :cancelled, lambda {
    where(cancelled: true)
  }

  scope :not_cancelled, lambda {
    where(cancelled: false)
  }

  def self.last_po
    maximum(:po_id).to_i
  end

  def send_po
    ApplicationMailer.po(self).deliver
  end

  def journal_entry_params
    {
      txn_date: date,
      doc_number: "APP-DO-#{id}"
    }
  end

  def journal_line_item_details
    details = []
    pos = []
    total_cost = 0

    daily_orders.not_cancelled.each do |daily_order|
      next unless daily_order.orders.count.positive?

      details << {
        account_id: Qbo::ACCOUNT_ID_BY_OUTLET[daily_order.outlet_name],
        amount: daily_order.total_cost,
        description: "Daily Inventory Transfer Cost of Goods for PO #{daily_order.display_po}",
        posting_type: 'Debit',
        class_id: Qbo::CLASS_ID_BY_OUTLET[daily_order.outlet_name]
      }
      total_cost += daily_order.total_cost
      pos << daily_order.display_po
    end

    unless total_cost.zero?
      details << {
        account_id: '3652', # 11137 Finished Goods - Shopify,
        amount: total_cost,
        description: "Daily Inventory Transfer total Cost of Goods for PO's: #{pos.join(', ')}",
        posting_type: 'Credit',
        class_id: Qbo.base_ref(Qbo::MOLLUSK_WEST_CLASS)
      }
    end

    details
  end

  def orders?
    daily_orders.find { |daily_order| daily_order.orders.exists? }
  end

  def post_to_qbo
    return unless orders?

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
        class_ref: Qbo.base_ref(details[:class_id]),
        posting_type: details[:posting_type]
      }

      line_item = Qbo.journal_entry_line_item(line_item_params, journal_entry_line_detail)

      journal_entry.line_items << line_item
    end

    journal_entry
  end

  def cancel
    return if cancelled?

    daily_orders.not_cancelled.each(&:cancel)

    if daily_orders.not_cancelled.count.zero?
      delete_qbo_journal_entry if qbo_id.present?
      update_attribute(:cancelled, true)
    end
  end

  def delete_qbo_journal_entry
    Qbo.delete_journal_entry(qbo_id)
    update_attribute(:qbo_id, nil)
  end

  def post_to_shopify
    daily_orders.each(&:post_to_shopify)
  end

  def post_to_inventory_planner
    daily_orders.each(&:create_ip_purchase_order)
  end
end

# == Schema Information
#
# Table name: daily_inventory_transfers
#
#  id         :bigint(8)        not null, primary key
#  cancelled  :boolean          default(FALSE)
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  po_id      :integer
#  qbo_id     :integer
#

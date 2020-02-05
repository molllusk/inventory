class DailyInventoryTransfer < ApplicationRecord
  has_many :daily_orders, dependent: :destroy

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

  def self.last_po
    maximum(:po_id).to_i
  end

  def send_po
    ApplicationMailer.po(self).deliver
  end

  def fluid_inventory
    retail_shopify_orders = ShopifyClient.order_quantities_by_variant
    product_ids = Order.where(daily_order_id: daily_orders.pluck(:id)).pluck(:product_id)
    Product.update_fluid_inventories(retail_shopify_orders, product_ids)
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

    daily_orders.each do |daily_order|
      if daily_order.orders.count.positive?
        details << {
          account_id: ACCOUNT_ID_BY_OUTLET[daily_order.outlet_name],
          amount: daily_order.total_cost,
          description: "Daily Inventory Transfer Cost of Goods for PO #{daily_order.display_po}",
          posting_type: 'Debit',
          class_id: CLASS_ID_BY_OUTLET[daily_order.outlet_name]
        }
        total_cost += daily_order.total_cost
        pos << daily_order.display_po
      end
    end

    if !total_cost.zero?
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

  def has_orders?
    daily_orders.find { |daily_order| daily_order.orders.count.positive? }
  end

  def post_to_qbo
    if has_orders?
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
# Table name: daily_inventory_transfers
#
#  id         :bigint(8)        not null, primary key
#  date       :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  po_id      :integer
#  qbo_id     :integer
#

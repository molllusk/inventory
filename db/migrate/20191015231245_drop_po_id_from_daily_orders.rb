class DropPoIdFromDailyOrders < ActiveRecord::Migration[5.2]
  def change
    remove_column :daily_orders, :po_id, :integer
  end
end

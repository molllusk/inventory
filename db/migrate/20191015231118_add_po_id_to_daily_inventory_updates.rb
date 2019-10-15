class AddPoIdToDailyInventoryUpdates < ActiveRecord::Migration[5.2]
  def changes
    add_column :daily_inventory_transfers, :po_id, :integer
  end
end

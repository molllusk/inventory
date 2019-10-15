class AddPoIdToDailyInventoryTransfers < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_inventory_transfers, :po_id, :integer
  end
end

class ChangeLocationOnInventoryUpdates < ActiveRecord::Migration[5.2]
  def up 
    change_column :inventory_updates, :location, :bigint
  end
end

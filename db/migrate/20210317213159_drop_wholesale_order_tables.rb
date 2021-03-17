class DropWholesaleOrderTables < ActiveRecord::Migration[5.2]
  def up
    drop_table :wholesale_orders
    drop_table :wholesale_order_items
    drop_table :inventory_updates
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

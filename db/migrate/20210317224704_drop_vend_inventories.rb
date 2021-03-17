class DropVendInventories < ActiveRecord::Migration[5.2]
  def up
    drop_table :vend_inventories
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end

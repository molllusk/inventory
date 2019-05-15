class CreateFluidInventoryUpdates < ActiveRecord::Migration[5.2]
  def change
    create_table :fluid_inventory_updates do |t|
      t.integer :prior_wholesale_qty
      t.integer :prior_retail_qty
      t.integer :adjustment
      t.integer :product_id
      t.integer :new_wholesale_qty
      t.integer :new_retail_qty

      t.timestamps
    end
  end
end

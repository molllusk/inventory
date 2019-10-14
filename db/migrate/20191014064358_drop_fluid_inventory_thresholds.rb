class DropFluidInventoryThresholds < ActiveRecord::Migration[5.2]
  def change
    drop_table :fluid_inventory_thresholds
  end
end

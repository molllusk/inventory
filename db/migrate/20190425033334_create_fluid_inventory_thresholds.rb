# frozen_string_literal: true

class CreateFluidInventoryThresholds < ActiveRecord::Migration[5.2]
  def change
    create_table :fluid_inventory_thresholds do |t|
      t.integer :threshold
      t.integer :product_type, limit: 8

      t.timestamps
    end
  end
end

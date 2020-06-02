# frozen_string_literal: true

class AddThresholdToFluidInventoryUpdates < ActiveRecord::Migration[5.2]
  def change
    add_column :fluid_inventory_updates, :threshold, :integer
  end
end

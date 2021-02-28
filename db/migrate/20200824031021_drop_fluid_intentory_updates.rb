# frozen_string_literal: true

class DropFluidIntentoryUpdates < ActiveRecord::Migration[5.2]
  def change
    drop_table :fluid_inventory_updates
  end
end

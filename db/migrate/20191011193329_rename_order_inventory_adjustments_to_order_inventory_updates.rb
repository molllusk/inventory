# frozen_string_literal: true

class RenameOrderInventoryAdjustmentsToOrderInventoryUpdates < ActiveRecord::Migration[5.2]
  def change
    rename_table :order_inventory_adjustments, :order_inventory_updates
  end
end

# frozen_string_literal: true

class AddUndoneToOrderInventoryUpdates < ActiveRecord::Migration[5.2]
  def change
    add_column :order_inventory_updates, :undone, :boolean, default: false
  end
end

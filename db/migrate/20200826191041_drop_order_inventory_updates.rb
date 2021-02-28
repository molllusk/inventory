# frozen_string_literal: true

class DropOrderInventoryUpdates < ActiveRecord::Migration[5.2]
  def change
    drop_table :order_inventory_updates
  end
end

# frozen_string_literal: true

class RemoveOrderInventoryAdjustmentIdFromOrders < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :order_inventory_adjustment_id, :integer
  end
end

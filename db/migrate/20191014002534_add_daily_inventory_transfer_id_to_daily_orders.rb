# frozen_string_literal: true

class AddDailyInventoryTransferIdToDailyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_orders, :daily_inventory_transfer_id, :integer
  end
end

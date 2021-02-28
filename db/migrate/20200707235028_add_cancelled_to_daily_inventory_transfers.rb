# frozen_string_literal: true

class AddCancelledToDailyInventoryTransfers < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_inventory_transfers, :cancelled, :boolean, default: false
  end
end

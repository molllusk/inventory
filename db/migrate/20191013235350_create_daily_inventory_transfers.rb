# frozen_string_literal: true

class CreateDailyInventoryTransfers < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_inventory_transfers do |t|
      t.datetime :date
      t.integer :qbo_id

      t.timestamps
    end
  end
end

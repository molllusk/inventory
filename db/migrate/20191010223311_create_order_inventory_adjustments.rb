# frozen_string_literal: true

class CreateOrderInventoryAdjustments < ActiveRecord::Migration[5.2]
  def change
    create_table :order_inventory_adjustments do |t|
      t.integer :prior_jam_qty
      t.integer :new_jam_qty
      t.integer :order_id

      t.timestamps
    end
  end
end

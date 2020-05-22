# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :orders do |t|
      t.string :vend_consignment_id
      t.integer :quantity
      t.integer :order_inventory_adjustment_id
      t.integer :product_id
      t.integer :daily_order_id
      t.integer :threshold
      t.integer :vend_qty

      t.timestamps
    end
  end
end

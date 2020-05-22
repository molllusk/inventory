# frozen_string_literal: true

class CreateInventoryUpdates < ActiveRecord::Migration[5.1]
  def change
    create_table :inventory_updates do |t|
      t.integer :product_id
      t.integer :adjustment
      t.integer :prior_qty
      t.integer :vend_qty
    end
  end
end

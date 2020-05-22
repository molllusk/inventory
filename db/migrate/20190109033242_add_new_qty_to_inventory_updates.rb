# frozen_string_literal: true

class AddNewQtyToInventoryUpdates < ActiveRecord::Migration[5.1]
  def change
    add_column :inventory_updates, :new_qty, :integer
  end
end

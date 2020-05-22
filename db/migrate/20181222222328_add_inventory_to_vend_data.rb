# frozen_string_literal: true

class AddInventoryToVendData < ActiveRecord::Migration[5.1]
  def change
    add_column :vend_data, :inventory, :integer
  end
end

# frozen_string_literal: true

class RemoveInventoryFromVendData < ActiveRecord::Migration[5.2]
  def change
    remove_column :vend_data, :inventory, :integer
  end
end

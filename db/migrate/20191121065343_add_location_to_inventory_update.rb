# frozen_string_literal: true

class AddLocationToInventoryUpdate < ActiveRecord::Migration[5.2]
  def change
    add_column :inventory_updates, :location, :integer, default: 49481991
  end
end

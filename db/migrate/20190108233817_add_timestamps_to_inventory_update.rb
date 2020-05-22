# frozen_string_literal: true

class AddTimestampsToInventoryUpdate < ActiveRecord::Migration[5.1]
  def change
    add_column :inventory_updates, :created_at, :datetime
    add_column :inventory_updates, :updated_at, :datetime
  end
end

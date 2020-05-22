# frozen_string_literal: true

class AddCostToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :cost, :float
  end
end

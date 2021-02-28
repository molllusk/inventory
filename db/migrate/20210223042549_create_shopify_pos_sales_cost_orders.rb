# frozen_string_literal: true

class CreateShopifyPosSalesCostOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_sales_cost_orders do |t|
      t.datetime :sale_at
      t.float :cost, default: 0.0
      t.bigint :location
      t.string :name
      t.integer :order_id
      t.integer :daily_shopify_pos_costs_id

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class CreateShopifyPosSalesCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_sales_costs do |t|
      t.float :cost, default: 0.0
      t.bigint :location
      t.integer :daily_shopify_pos_costs_id

      t.timestamps
    end
  end
end

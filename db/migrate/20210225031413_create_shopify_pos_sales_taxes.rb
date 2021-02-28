# frozen_string_literal: true

class CreateShopifyPosSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_sales_taxes do |t|
      t.integer :daily_shopify_pos_sale_id

      t.timestamps
    end
  end
end

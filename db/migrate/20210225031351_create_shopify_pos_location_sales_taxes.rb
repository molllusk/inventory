# frozen_string_literal: true

class CreateShopifyPosLocationSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_location_sales_taxes do |t|
      t.float :amount, default: 0.0
      t.float :sales_tax, default: 0.0
      t.float :shipping, default: 0.0
      t.bigint :location
      t.integer :shopify_pos_sales_tax_id

      t.timestamps
    end
  end
end

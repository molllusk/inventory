# frozen_string_literal: true

class CreateShopifyRefunds < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_refunds do |t|
      t.float :cost, default: 0
      t.float :product_sales, default: 0
      t.float :sales_tax, default: 0
      t.float :discount, default: 0
      t.float :paypal_payments, default: 0
      t.float :total_payments, default: 0
      t.float :shopify_payments, default: 0
      t.float :shipping, default: 0
      t.float :gift_card_payments, default: 0
      t.json :location_costs, default: {}
      t.datetime :date

      t.timestamps
    end
  end
end

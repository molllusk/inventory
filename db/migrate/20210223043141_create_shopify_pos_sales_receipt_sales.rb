# frozen_string_literal: true

class CreateShopifyPosSalesReceiptSales < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_sales_receipt_sales do |t|
      t.float :gift_card_sales, default: 0.0
      t.float :gift_card_payments, default: 0.0
      t.float :credit_payments, default: 0.0
      t.float :cash_payments, default: 0.0
      t.float :product_sales, default: 0.0
      t.float :discount, default: 0.0
      t.float :discount_sales, default: 0.0
      t.float :sales_tax, default: 0.0
      t.float :shipping, default: 0.0
      t.bigint :location
      t.integer :daily_shopify_pos_sale_id
      t.string :name
      t.datetime :sale_at
      t.bigint :order_id
      t.float :rentals, default: 0.0

      t.timestamps
    end
  end
end

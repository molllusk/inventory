# frozen_string_literal: true

class CreateShopifySalesReceiptOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_sales_receipt_orders do |t|
      t.integer :order_id, limit: 8
      t.string :name
      t.datetime :closed_at
      t.float :sales_tax, default: 0
      t.float :discount, default: 0
      t.float :product_sales, default: 0
      t.float :shipping, default: 0
      t.float :shopify_payments, default: 0
      t.float :gift_card_payments, default: 0
      t.float :paypal_payments, default: 0
      t.float :gift_card_sales, default: 0
      t.integer :shopify_sales_receipt_id

      t.timestamps
    end
  end
end

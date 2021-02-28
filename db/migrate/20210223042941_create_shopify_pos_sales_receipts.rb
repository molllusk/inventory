# frozen_string_literal: true

class CreateShopifyPosSalesReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_sales_receipts do |t|
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
      t.bigint :qbo_id

      t.timestamps
    end
  end
end

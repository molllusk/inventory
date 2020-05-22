# frozen_string_literal: true

class CreateShopifySalesReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_sales_receipts do |t|
      t.float :product_sales, default: 0
      t.float :discount, default: 0
      t.float :shipping, default: 0
      t.float :sales_tax, default: 0
      t.float :gift_card_sales, default: 0
      t.float :shopify_payments, default: 0
      t.float :gift_card_payments, default: 0
      t.float :paypal_payments, default: 0
      t.datetime :date

      t.timestamps
    end
  end
end

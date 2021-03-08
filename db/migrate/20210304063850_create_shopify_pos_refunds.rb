# frozen_string_literal: true

class CreateShopifyPosRefunds < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_pos_refunds do |t|
      t.float :arbitrary_discount, default: 0.0
      t.float :cost, default: 0.0
      t.float :discount, default: 0.0
      t.float :gift_card_payments, default: 0.0
      t.float :paypal_payments, default: 0.0
      t.float :product_sales, default: 0.0
      t.float :refunded_shipping, default: 0.0
      t.float :sales_tax, default: 0.0
      t.float :shipping, default: 0.0
      t.float :shopify_payments, default: 0.0
      t.float :total_payments, default: 0.0
      t.float :cash_payments, default: 0.0
      t.integer :shopify_refund_id
      t.bigint :location_id

      t.timestamps
    end
  end
end

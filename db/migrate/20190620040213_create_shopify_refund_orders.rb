# frozen_string_literal: true

class CreateShopifyRefundOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_refund_orders do |t|
      t.integer :order_id, limit: 8
      t.string :name
      t.datetime :created_at
      t.integer :shopify_refund_id
      t.float :cost, default: 0
      t.float :discount, default: 0
      t.float :gift_card_payments, default: 0
      t.float :shopify_payments, default: 0
      t.float :paypal_payments, default: 0
      t.json :location_costs
      t.float :paypal_payments, default: 0
      t.float :product_sales, default: 0
      t.float :refunded_shipping, default: 0
      t.float :sales_tax, default: 0
      t.float :shipping, default: 0
      t.float :total_payments, default: 0

      t.timestamps
    end
  end
end

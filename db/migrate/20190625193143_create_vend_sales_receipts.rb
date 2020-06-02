# frozen_string_literal: true

class CreateVendSalesReceipts < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_sales_receipts do |t|
      t.float :gift_card_sales, default: 0
      t.float :gift_card_payments, default: 0
      t.float :credit_payments, default: 0
      t.float :cash_or_check_payments, default: 0
      t.float :product_sales, default: 0
      t.float :discount, default: 0
      t.float :sales_tax, default: 0
      t.string :outlet_id
      t.float :shipping, default: 0
      t.integer :daily_vend_sale_id

      t.timestamps
    end
  end
end

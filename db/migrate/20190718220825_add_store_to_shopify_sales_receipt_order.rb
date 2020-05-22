# frozen_string_literal: true

class AddStoreToShopifySalesReceiptOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_receipt_orders, :store, :integer, default: 0
  end
end

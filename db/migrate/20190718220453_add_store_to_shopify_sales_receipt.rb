# frozen_string_literal: true

class AddStoreToShopifySalesReceipt < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_receipts, :store, :integer, default: 0
  end
end

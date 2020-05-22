# frozen_string_literal: true

class AddQboIdToShopifySalesReceipts < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_receipts, :qbo_id, :integer, limit: 8
  end
end

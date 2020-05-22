# frozen_string_literal: true

class AddQboIdToVendSalesReceipts < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_receipts, :qbo_id, :integer, limit: 8
  end
end

# frozen_string_literal: true

class AddReceiptNumnerToVendSalesReceiptSales < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_receipt_sales, :receipt_number, :integer
  end
end

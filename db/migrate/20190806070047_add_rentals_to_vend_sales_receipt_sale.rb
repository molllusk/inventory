class AddRentalsToVendSalesReceiptSale < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_receipt_sales, :rentals, :float, default: 0
  end
end

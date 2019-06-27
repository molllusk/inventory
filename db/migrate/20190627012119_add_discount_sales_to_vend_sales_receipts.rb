class AddDiscountSalesToVendSalesReceipts < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_receipts, :discount_sales, :float, default: 0
  end
end

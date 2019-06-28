class AddReceiptNumnerToVendSalesCostSales < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_cost_sales, :receipt_number, :integer
  end
end

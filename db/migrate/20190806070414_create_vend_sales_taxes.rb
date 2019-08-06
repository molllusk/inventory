class CreateVendSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_sales_taxes do |t|

      t.timestamps
    end
  end
end

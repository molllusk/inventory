class CreateVendLocationSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_location_sales_taxes do |t|
      t.integer :vend_sales_tax_id
      t.float :sales_tax, default: 0
      t.float :shipping, default: 0
      t.float :amount, default: 0
      t.string :outlet_id

      t.timestamps
    end
  end
end

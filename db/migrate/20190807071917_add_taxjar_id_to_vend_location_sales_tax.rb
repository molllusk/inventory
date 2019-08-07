class AddTaxjarIdToVendLocationSalesTax < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_location_sales_taxes, :taxjar_id, :string
  end
end

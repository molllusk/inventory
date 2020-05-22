# frozen_string_literal: true

class RemoveTaxjarIdFromVendLocationSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    remove_column :vend_location_sales_taxes, :taxjar_id, :string
  end
end

# frozen_string_literal: true

class AddDateToVendSalesTax < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_sales_taxes, :daily_vend_sale_id, :integer
  end
end

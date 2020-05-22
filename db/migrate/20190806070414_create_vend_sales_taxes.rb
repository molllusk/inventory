# frozen_string_literal: true

class CreateVendSalesTaxes < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_sales_taxes, &:timestamps
  end
end

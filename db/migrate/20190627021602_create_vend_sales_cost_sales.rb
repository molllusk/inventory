# frozen_string_literal: true

class CreateVendSalesCostSales < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_sales_cost_sales do |t|
      t.float :cost, default: 0
      t.string :outlet_id
      t.string :sale_id
      t.integer :daily_vend_cost_id
      t.datetime :sale_at

      t.timestamps
    end
  end
end

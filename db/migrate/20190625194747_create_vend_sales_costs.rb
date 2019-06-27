class CreateVendSalesCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_sales_costs do |t|
      t.string :outlet_id
      t.integer :daily_vend_cost_id
      t.float :cost, default: 0

      t.timestamps
    end
  end
end

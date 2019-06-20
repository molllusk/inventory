class CreateShopifySalesCostOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_sales_cost_orders do |t|
      t.integer :order_id, limit: 8
      t.string :name
      t.datetime :closed_at
      t.float :cost, default: 0
      t.json :location_costs
      t.integer :shopify_sales_cost_id

      t.timestamps
    end
  end
end

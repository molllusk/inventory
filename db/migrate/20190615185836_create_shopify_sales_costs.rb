class CreateShopifySalesCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_sales_costs do |t|
      t.float :cost, default: 0
      t.json :location_costs, default: {}
      t.datetime :date

      t.timestamps
    end
  end
end

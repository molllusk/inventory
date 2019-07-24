class AddQboIdToShopifySalesCosts < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_costs, :qbo_id, :integer, limit: 8
  end
end

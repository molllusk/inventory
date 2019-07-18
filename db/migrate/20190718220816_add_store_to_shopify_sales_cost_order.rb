class AddStoreToShopifySalesCostOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_cost_orders, :store, :integer, default: 0
  end
end

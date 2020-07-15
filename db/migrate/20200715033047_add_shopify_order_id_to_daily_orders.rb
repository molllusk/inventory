class AddShopifyOrderIdToDailyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_orders, :shopify_order_id, :bigint
  end
end

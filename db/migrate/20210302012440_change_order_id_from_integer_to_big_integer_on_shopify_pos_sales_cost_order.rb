class ChangeOrderIdFromIntegerToBigIntegerOnShopifyPosSalesCostOrder < ActiveRecord::Migration[5.2]
  def change
    change_column :shopify_pos_sales_cost_orders, :order_id, :bigint
  end
end

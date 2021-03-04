class AddPosLocationIdAndCashPaymentsToShopifyRefundOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_refund_orders, :cash_payments, :float, default: 0.0
    add_column :shopify_refund_orders, :pos_location_id, :bigint
  end
end

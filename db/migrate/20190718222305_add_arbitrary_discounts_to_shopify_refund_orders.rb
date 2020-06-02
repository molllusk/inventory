# frozen_string_literal: true

class AddArbitraryDiscountsToShopifyRefundOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_refund_orders, :arbitrary_discount, :float, default: 0.0
  end
end

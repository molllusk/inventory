class AddRefundedShippingToShopifyRefunds < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_refunds, :refunded_shipping, :float, default: 0
  end
end

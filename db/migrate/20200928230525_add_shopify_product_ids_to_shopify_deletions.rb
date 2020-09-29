class AddShopifyProductIdsToShopifyDeletions < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_deletions, :deleted_shopify_product_id, :bigint
    add_column :shopify_deletions, :new_shopify_product_id, :bigint
  end
end

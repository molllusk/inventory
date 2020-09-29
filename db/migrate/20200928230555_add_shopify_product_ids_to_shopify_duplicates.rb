class AddShopifyProductIdsToShopifyDuplicates < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_duplicates, :original_shopify_product_id, :bigint
    add_column :shopify_duplicates, :duplicate_shopify_product_id, :bigint
  end
end

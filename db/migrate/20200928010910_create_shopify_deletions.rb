class CreateShopifyDeletions < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_deletions do |t|
      t.integer :product_id
      t.bigint :deleted_variant_id
      t.bigint :new_variant_id

      t.timestamps
    end
  end
end

class RemoveStoreFromShopifyData < ActiveRecord::Migration[5.2]
  def change
    remove_column :shopify_data, :store, :integer
  end
end

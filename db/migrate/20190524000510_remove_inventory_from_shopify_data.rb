class RemoveInventoryFromShopifyData < ActiveRecord::Migration[5.2]
  def change
    remove_column :shopify_data, :inventory, :integer
  end
end

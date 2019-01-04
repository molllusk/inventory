class AddInventoryToShopifyData < ActiveRecord::Migration[5.1]
  def change
    add_column :shopify_data, :inventory, :integer
  end
end

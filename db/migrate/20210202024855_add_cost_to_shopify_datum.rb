class AddCostToShopifyDatum < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_data, :cost, :float, default: 0.0
  end
end

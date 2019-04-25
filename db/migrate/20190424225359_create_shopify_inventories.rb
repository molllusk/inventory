class CreateShopifyInventories < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_inventories do |t|
      t.integer :inventory_location
      t.integer :inventory
      t.integer :shopify_datum_id

      t.timestamps
    end
  end
end

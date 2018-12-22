class CreateShopifyData < ActiveRecord::Migration[5.1]
  def change
    create_table :shopify_data do |t|

      t.timestamps
      t.string :handle
      t.string :product_type
      t.text :tags
      t.string :title
      t.string :vendor
      t.string :barcode
      t.string :compare_at_price
      t.string :fulfillment_service
      t.integer :grams
      t.integer :inventory_item_id, limit: 8
      t.string :inventory_management
      t.string :inventory_policy
      t.integer :inventory_quantity
      t.integer :old_inventory_quantity
      t.string :price
      t.integer :shopify_product_id, limit: 8
      t.integer :variant_id, limit: 8
      t.string :requires_shipping
      t.string :sku
      t.string :variant_title
      t.float :weight
      t.string :weight_unit
      t.timestamp :variant_created_at
      t.timestamp :shopify_created_at
      t.integer :product_id
    end
  end
end

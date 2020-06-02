# frozen_string_literal: true

class CreateVendData < ActiveRecord::Migration[5.1]
  def change
    create_table :vend_data do |t|
      t.boolean :active
      t.string :brand
      t.string :brand_id
      t.text :categories
      t.timestamp :vend_created_at
      t.timestamp :vend_deleted_at
      t.text :description
      t.string :handle
      t.boolean :has_inventory
      t.boolean :has_variants
      t.string :vend_id
      t.boolean :is_active
      t.string :name
      t.string :product_type_id
      t.string :sku
      t.string :supplier
      t.string :supplier_id
      t.string :supply_price
      t.text :tag_ids
      t.text :vend_type
      t.string :variant_count
      t.string :variant_name
      t.text :variant_options
      t.string :variant_parent_id
      t.integer :product_id

      t.timestamps
    end
  end
end

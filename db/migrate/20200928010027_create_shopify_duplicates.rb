# frozen_string_literal: true

class CreateShopifyDuplicates < ActiveRecord::Migration[5.2]
  def change
    create_table :shopify_duplicates do |t|
      t.integer :product_id
      t.bigint :original_variant_id
      t.bigint :duplicate_variant_id

      t.timestamps
    end
  end
end

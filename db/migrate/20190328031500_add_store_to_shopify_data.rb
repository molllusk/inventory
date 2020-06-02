# frozen_string_literal: true

class AddStoreToShopifyData < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_data, :store, :integer
  end
end

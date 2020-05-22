# frozen_string_literal: true

class AddStoreToShopifySalesCost < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_sales_costs, :store, :integer, default: 0
  end
end

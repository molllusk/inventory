# frozen_string_literal: true

class AddArbitraryDiscountsToShopifyRefunds < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_refunds, :arbitrary_discount, :float, default: 0.0
  end
end

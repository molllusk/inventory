# frozen_string_literal: true

class AddQboIdToShopifyRefunds < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_refunds, :qbo_id, :integer, limit: 8
  end
end

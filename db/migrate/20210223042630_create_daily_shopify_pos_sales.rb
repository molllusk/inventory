# frozen_string_literal: true

class CreateDailyShopifyPosSales < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_shopify_pos_sales do |t|
      t.datetime :date

      t.timestamps
    end
  end
end

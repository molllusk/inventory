# frozen_string_literal: true

class RenameDailyShopifyPosCostsId < ActiveRecord::Migration[5.2]
  def change
    change_table :shopify_pos_sales_costs do |t|
      t.rename :daily_shopify_pos_costs_id, :daily_shopify_pos_cost_id
    end

    change_table :shopify_pos_sales_cost_orders do |t|
      t.rename :daily_shopify_pos_costs_id, :daily_shopify_pos_cost_id
    end
  end
end

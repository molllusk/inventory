# frozen_string_literal: true

class ShopifyPosSalesCost < ApplicationRecord
  belongs_to :daily_shopify_pos_cost, optional: true

  def outlet_name
    ShopifyClient::OUTLET_NAMES_BY_ID[location]
  end
end

# == Schema Information
#
# Table name: shopify_pos_sales_costs
#
#  id                        :bigint(8)        not null, primary key
#  cost                      :float            default(0.0)
#  location                  :bigint(8)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_shopify_pos_cost_id :integer
#

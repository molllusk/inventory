# frozen_string_literal: true

class ShopifySalesCostOrder < ApplicationRecord
  belongs_to :shopify_sales_cost, optional: true

  enum store: {
    retail: 0,
    wholesale: 1
  }
end

# == Schema Information
#
# Table name: shopify_sales_cost_orders
#
#  id                    :bigint(8)        not null, primary key
#  closed_at             :datetime
#  cost                  :float            default(0.0)
#  location_costs        :json
#  name                  :string
#  store                 :integer          default("retail")
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  order_id              :bigint(8)
#  shopify_sales_cost_id :integer
#

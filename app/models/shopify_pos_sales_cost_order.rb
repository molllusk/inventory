class ShopifyPosSalesCostOrder < ApplicationRecord
  belongs_to :daily_shoipify_pos_cost, optional: true

  def outlet_name
    # VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end
end

# == Schema Information
#
# Table name: shopify_pos_sales_cost_orders
#
#  id                         :bigint(8)        not null, primary key
#  cost                       :float            default(0.0)
#  location                   :bigint(8)
#  name                       :string
#  sale_at                    :datetime
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  daily_shopify_pos_costs_id :integer
#  order_id                   :integer
#

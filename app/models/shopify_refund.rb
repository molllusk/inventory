class ShopifyRefund < ApplicationRecord
end

# == Schema Information
#
# Table name: shopify_refunds
#
#  id                 :bigint(8)        not null, primary key
#  cost               :float            default(0.0)
#  date               :datetime
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  location_costs     :json
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  total_payments     :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

# frozen_string_literal: true

class ShopifyRefundOrder < ApplicationRecord
  belongs_to :shopify_refund, optional: true

  enum pos_location_id: {
    # retail site
    'San Francisco' => 49481991,
    'Santa Barbara' => 7_702_609_973,
    'Venice Beach' => 7_702_577_205
  }
end

# == Schema Information
#
# Table name: shopify_refund_orders
#
#  id                 :bigint(8)        not null, primary key
#  arbitrary_discount :float            default(0.0)
#  cash_payments      :float            default(0.0)
#  cost               :float            default(0.0)
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  location_costs     :json
#  name               :string
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  refunded_shipping  :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  total_payments     :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  order_id           :bigint(8)
#  pos_location_id    :bigint(8)
#  shopify_refund_id  :integer
#

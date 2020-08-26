# frozen_string_literal: true

class Order < ApplicationRecord
  belongs_to :product
  belongs_to :daily_order

  scope :cancelled, lambda {
    where(cancelled: true)
  }

  scope :not_cancelled, lambda {
    where(cancelled: false)
  }

  def cancel
    return if cancelled?
    update_attribute(:cancelled, true)
  end

  def total_cost
    cost * quantity
  end

  def shopify_line_item
    {
      variant_id: product.retail_shopify.variant_id,
      quantity: quantity,
      price: product.retail_shopify.price.to_f
    }
  end
end

# == Schema Information
#
# Table name: orders
#
#  id             :bigint(8)        not null, primary key
#  cancelled      :boolean          default(FALSE)
#  cost           :float
#  quantity       :integer
#  sent_orders    :integer          default(0)
#  threshold      :integer
#  vend_qty       :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  daily_order_id :integer
#  product_id     :integer
#

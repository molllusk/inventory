class Order < ApplicationRecord
  belongs_to :product
  belongs_to :daily_order
  has_one    :order_inventory_adjustment, dependent: :destroy
end

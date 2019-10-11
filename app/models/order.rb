class Order < ApplicationRecord
  belongs_to :product
  belongs_to :daily_order
  has_one    :order_inventory_adjustment, dependent: :destroy

end

# == Schema Information
#
# Table name: orders
#
#  id                            :bigint(8)        not null, primary key
#  cost                          :float
#  quantity                      :integer
#  threshold                     :integer
#  vend_qty                      :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  daily_order_id                :integer
#  order_inventory_adjustment_id :integer
#  product_id                    :integer
#

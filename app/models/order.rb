class Order < ApplicationRecord
  belongs_to :product
  belongs_to :daily_order
  has_one    :order_inventory_update, dependent: :destroy

  after_create :reduce_jam_inventory

  def reduce_jam_inventory
    puts "Reducing... haha NOT!"
    # product.adjust_order_inventory(self)
  end
end

# == Schema Information
#
# Table name: orders
#
#  id             :bigint(8)        not null, primary key
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

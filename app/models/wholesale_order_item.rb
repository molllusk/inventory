class WholesaleOrderItem < ApplicationRecord
  belongs_to :wholesale_order
end

# == Schema Information
#
# Table name: wholesale_order_items
#
#  id                 :bigint(8)        not null, primary key
#  cancel_date        :datetime
#  customer           :string
#  customer_po        :string
#  department         :string
#  item_name          :string
#  location           :string
#  quantity_ordered   :integer
#  ref_number         :string
#  start_ship         :datetime
#  txn_date           :datetime
#  wholesale_order_id :integer
#

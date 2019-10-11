class OrderInventoryUpdate < ApplicationRecord
  belongs_to :order
end

# == Schema Information
#
# Table name: order_inventory_updates
#
#  id            :bigint(8)        not null, primary key
#  new_jam_qty   :integer
#  prior_jam_qty :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  order_id      :integer
#

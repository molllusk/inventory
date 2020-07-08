# frozen_string_literal: true

class OrderInventoryUpdate < ApplicationRecord
  belongs_to :order

  def success?
    new_jam_qty == (prior_jam_qty - order.quantity)
  end

  def undo
    update_attribute(:undone, true)
  end

  # need to add an undo method here
  def undo; end
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

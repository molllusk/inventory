# frozen_string_literal: true

class WholesaleOrderItem < ApplicationRecord
  belongs_to :wholesale_order

  def self.sos_items
    @sos_items ||= SosClient.items
  end

  def self.items_post_data(items)
    item_params = []
    items.each_with_index { |item, index| item_params << item.compile_post_data(index + 1) }
    item_params
  end

  def compile_post_data(index)
    defaults = {
      volume: 0,
      weightunit: 'lb',
      volumeunit: '',
      altAmount: 0,
      picked: 0,
      shipped: 0,
      invoiced: 0,
      produced: 0,
      returned: 0,
      linenumber: index
    }

    defaults[:quantity] = quantity_ordered
    defaults[:duedate] = wholesale_order.cancel_date.strftime('%Y-%m-%dT%H:%M:%S')
    defaults[:description] = sos_item['description']
    defaults[:unitprice] = sos_item['salesPrice']
    defaults[:amount] = sos_item['salesPrice'] * quantity_ordered
    defaults[:weight] = sos_item['weight']
    defaults[:class] = { id: 1 }
    defaults[:tax] = { taxable: false }
    defaults[:item] = { id: sos_item['id'], name: item_name }

    update_attribute(:sos_item_id, sos_item['id'])
    update_attribute(:unit_price, sos_item['salesPrice'])
    defaults
  end

  def sos_item
    @sos_item ||= WholesaleOrderItem.sos_items.find { |sos_item| sos_item['name'] == item_name }
  end
end

# == Schema Information
#
# Table name: wholesale_order_items
#
#  id                 :bigint(8)        not null, primary key
#  department         :string
#  item_name          :string
#  quantity_ordered   :integer          default(0)
#  unit_price         :float            default(0.0)
#  sos_item_id        :bigint(8)
#  wholesale_order_id :integer
#

# frozen_string_literal: true

class AddVendConsignmentIdToDailyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_orders, :vend_consignment_id, :string
  end
end

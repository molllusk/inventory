# frozen_string_literal: true

class ChangePoIdToBeIntegerInDailyOrders < ActiveRecord::Migration[5.2]
  def change
    change_column :daily_orders, :po_id, 'integer USING CAST(po_id AS integer)'
  end
end

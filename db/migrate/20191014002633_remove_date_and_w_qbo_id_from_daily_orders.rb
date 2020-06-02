# frozen_string_literal: true

class RemoveDateAndWQboIdFromDailyOrders < ActiveRecord::Migration[5.2]
  def change
    remove_column :daily_orders, :qbo_id, :integer
    remove_column :daily_orders, :date, :datetime
  end
end

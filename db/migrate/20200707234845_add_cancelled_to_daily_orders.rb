class AddCancelledToDailyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_orders, :cancelled, :boolean, default: false
  end
end

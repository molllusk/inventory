class AddCancelledToOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :cancelled, :boolean, default: false
  end
end

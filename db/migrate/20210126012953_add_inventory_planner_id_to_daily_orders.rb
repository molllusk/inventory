class AddInventoryPlannerIdToDailyOrders < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_orders, :inventory_planner_id, :string
  end
end

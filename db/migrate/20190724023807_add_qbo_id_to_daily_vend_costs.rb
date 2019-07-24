class AddQboIdToDailyVendCosts < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_vend_costs, :qbo_id, :integer, limit: 8
  end
end

class CreateDailyOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_orders do |t|
      t.string :outlet_id
      t.string :po_id
      t.integer :qbo_id, limit: 8
      t.datetime :date

      t.timestamps
    end
  end
end

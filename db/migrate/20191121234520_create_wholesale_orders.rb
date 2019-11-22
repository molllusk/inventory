class CreateWholesaleOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_orders do |t|

      t.timestamps
    end
  end
end

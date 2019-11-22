class CreateWholesaleOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_order_items do |t|
      t.string :ref_number
      t.string :customer
      t.datetime :txn_date
      t.string :customer_po
      t.string :department
      t.string :location
      t.datetime :start_ship
      t.datetime :cancel_date
      t.string :item_name
      t.integer :quantity_ordered
      t.integer :wholesale_order_id
    end
  end
end

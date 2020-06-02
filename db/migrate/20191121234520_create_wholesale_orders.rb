# frozen_string_literal: true

class CreateWholesaleOrders < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_orders do |t|
      t.integer :sos_id
      t.string :ref_number
      t.string :customer
      t.string :customer_po
      t.bigint :sos_customer_id
      t.string :location
      t.datetime :start_ship
      t.datetime :cancel_date
      t.float :sos_total
      t.timestamps
    end
  end
end

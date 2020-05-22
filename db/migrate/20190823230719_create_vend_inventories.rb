# frozen_string_literal: true

class CreateVendInventories < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_inventories do |t|
      t.integer :inventory
      t.string :outlet_id
      t.integer :vend_datum_id

      t.timestamps
    end
  end
end

class CreateWholesaleOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_order_items do |t|
      t.string :department
      t.string :item_name
      t.float :unit_price, default: 0
      t.bigint :sos_item_id
      t.integer :quantity_ordered, default: 0
      t.integer :wholesale_order_id
    end
  end
end

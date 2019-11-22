class CreateWholesaleOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_order_items do |t|
      t.string :department
      t.string :item_name
      t.integer :quantity_ordered
      t.integer :wholesale_order_id
    end
  end
end

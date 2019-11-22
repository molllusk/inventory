class CreateWholesaleOrderItems < ActiveRecord::Migration[5.2]
  def change
    create_table :wholesale_order_items do |t|

      t.timestamps
    end
  end
end

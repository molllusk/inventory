class AddSentOrdersToOrder < ActiveRecord::Migration[5.2]
  def change
    add_column :orders, :sent_orders, :integer, default: 0
  end
end

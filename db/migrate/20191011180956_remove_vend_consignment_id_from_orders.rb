class RemoveVendConsignmentIdFromOrders < ActiveRecord::Migration[5.2]
  def change
    remove_column :orders, :vend_consignment_id, :string
  end
end

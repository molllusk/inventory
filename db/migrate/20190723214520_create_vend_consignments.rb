class CreateVendConsignments < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_consignments do |t|
      t.integer :daily_vend_consignment_id
      t.float :cost, default: 0
      t.string :receiving_id
      t.string :supplying_id
      t.string :vend_consignment_id

      t.timestamps
    end
  end
end

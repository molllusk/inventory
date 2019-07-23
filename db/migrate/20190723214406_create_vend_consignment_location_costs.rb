class CreateVendConsignmentLocationCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :vend_consignment_location_costs do |t|
      t.integer :daily_vend_consignment_id
      t.float :cost, default: 0
      t.string :outlet_id
      t.integer :role, default: 0

      t.timestamps
    end
  end
end

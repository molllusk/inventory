class AddQboIdToDailyVendConsignments < ActiveRecord::Migration[5.2]
  def change
    add_column :daily_vend_consignments, :qbo_id, :integer, limit: 8
  end
end

class CreateDailyShopifyPosCosts < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_shopify_pos_costs do |t|
      t.datetime :date
      t.bigint :qbo_id

      t.timestamps
    end
  end
end

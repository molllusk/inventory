# frozen_string_literal: true

class CreateDailyVendConsignments < ActiveRecord::Migration[5.2]
  def change
    create_table :daily_vend_consignments do |t|
      t.datetime :date

      t.timestamps
    end
  end
end

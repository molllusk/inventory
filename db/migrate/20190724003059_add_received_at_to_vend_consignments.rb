# frozen_string_literal: true

class AddReceivedAtToVendConsignments < ActiveRecord::Migration[5.2]
  def change
    add_column :vend_consignments, :received_at, :datetime
  end
end

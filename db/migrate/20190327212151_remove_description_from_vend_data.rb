# frozen_string_literal: true

class RemoveDescriptionFromVendData < ActiveRecord::Migration[5.2]
  def change
    remove_column :vend_data, :description, :text
  end
end

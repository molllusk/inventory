# frozen_string_literal: true

class CreateQboTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :qbo_tokens do |t|
      t.string :token
      t.string :secret
      t.string :realm_id

      t.timestamps
    end
  end
end

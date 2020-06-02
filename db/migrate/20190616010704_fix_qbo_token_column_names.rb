# frozen_string_literal: true

class FixQboTokenColumnNames < ActiveRecord::Migration[5.2]
  def change
    rename_column :qbo_tokens, :secret, :refresh_token
  end
end

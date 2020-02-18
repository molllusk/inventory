class CreateSosTokens < ActiveRecord::Migration[5.2]
  def change
    create_table :sos_tokens do |t|
      t.text :access_token
      t.text :refresh_token
      t.integer :expires_in
      t.string :token_type

      t.timestamps
    end
  end
end

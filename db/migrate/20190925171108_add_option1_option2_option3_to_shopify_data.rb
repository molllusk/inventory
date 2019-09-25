class AddOption1Option2Option3ToShopifyData < ActiveRecord::Migration[5.2]
  def change
    add_column :shopify_data, :option1, :string
    add_column :shopify_data, :option2, :string
    add_column :shopify_data, :option3, :string
  end
end

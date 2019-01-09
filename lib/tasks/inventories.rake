namespace :inventories do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    VendClient.update_inventories
    ShopifyClient.update_inventories
    Product.update_inventories
  end
end

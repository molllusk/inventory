namespace :inventories do
  desc "TODO"
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    VendClient.update_inventories
    ShopifyClient.update_inventories
  end
end

# frozen_string_literal: true

namespace :inventories do
  task pull: :environment do
    VendClient.update_inventories
    ShopifyClient.update_inventories
    ShopifyClient.update_inventories(:WHOLESALE)
    Product.run_inventory_updates
  end
end

# frozen_string_literal: true

namespace :inventories do
  task pull: :environment do
    # VendClient.update_inventories
    ShopifyClient.update_inventories
    # Product.run_inventory_updates # sync vend and shopify inventories (becoming obsolete)
  end
end

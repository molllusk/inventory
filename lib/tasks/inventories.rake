# frozen_string_literal: true

namespace :inventories do
  task pull: :environment do
    ShopifyDatum.update_inventories
    ShopifyDatum.connect_required_inventory_locations
  end
end

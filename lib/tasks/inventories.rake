# frozen_string_literal: true

namespace :inventories do
  task pull: :environment do
    ShopifyClient.update_inventories
  end
end

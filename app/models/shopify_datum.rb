class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true

  def full_title
    "#{title} - #{variant_title}"
  end

  def sf_inventory
    ShopifyClient.get_sf_inventory(inventory_item_id)
  end
end

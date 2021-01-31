# frozen_string_literal: true

class ShopifyInventory < ApplicationRecord
  belongs_to :shopify_datum

  scope :with_warehouse, -> { where('location = ? AND inventory > 0', ShopifyInventory.locations['Shopify Fulfillment Network']) }
  scope :exclude_dead_locations, -> { where.not(location: DEAD_LOCATIONS) }
  scope :order_by_location, -> { order(:location) }

  enum location: {
    # retail site
    'Jam Warehouse Retail' => 7700054069,
    'Mollusk SF' => 49481991,
    'Mollusk SB' => 7702609973,
    'Mollusk VB' => 7702577205,
    'Postworks' => 18186895445,
    'Shopify Fulfillment Network' => 36225056853
  }

  DEAD_LOCATIONS = ['Jam Warehouse Retail', 'Postworks']
end

# == Schema Information
#
# Table name: shopify_inventories
#
#  id               :bigint(8)        not null, primary key
#  inventory        :integer
#  location         :bigint(8)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  shopify_datum_id :integer
#

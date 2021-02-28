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

  DEAD_LOCATIONS = ['Jam Warehouse Retail', 'Postworks'].freeze

  # This is transitional and won't be needed once vend is fully deprecated
  VEND_OUTLET_NAMES_BY_LOCATION = {
    'Mollusk SF' => '5e234f4e-8eed-11e0-8e09-4040f540b50a',
    'Mollusk SB' => '8d27bed3-060b-11e4-a0f5-b8ca3a64f8f4',
    'Mollusk VB' => '0adfd74a-153e-11e9-fa42-67b5781ba1fb'
  }.freeze

  def self.active_locations
    locations.keys - DEAD_LOCATIONS
  end

  # This is transitional and won't be needed once vend is fully deprecated
  def outlet_id
    VEND_OUTLET_NAMES_BY_LOCATION[location]
  end
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

# frozen_string_literal: true

class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true
  has_many :shopify_inventories, dependent: :destroy

  scope :with_warehouse, -> { joins(:shopify_inventories).merge(ShopifyInventory.with_warehouse) }

  def self.connect_required_inventory_locations
    find_each do |shopify_datum|
      missing_locations = ShopifyInventory::REQUIRED_LOCATIONS - shopify_datum.shopify_inventories.pluck(:location)
      missing_locations.each do |location|
        shopify_datum.connect_inventory_location(location)
      end
    end
  end

  def self.update_inventories
    inventory_item_ids = pluck(:inventory_item_id)

    while inventory_item_ids.present?
      id_batch = inventory_item_ids.shift(50)
      all_inventory_levels = ShopifyClient.get_inventory_levels_all_locations(id_batch)

      all_inventory_levels.each do |inventory_level|
        if inventory_level['available'].present?
          sd = find_by(inventory_item_id: inventory_level['inventory_item_id'])
          existing_inventory_item = sd.shopify_inventories.find_by(location: inventory_level['location_id'])

          if existing_inventory_item.present?
            existing_inventory_item.update_attribute(:inventory, inventory_level['available']) if existing_inventory_item.inventory != inventory_level['available']
          else
            sd.shopify_inventories.create(location: inventory_level['location_id'], inventory: inventory_level['available'])
          end
        end
      end
    end
  end

  def connect_inventory_location(outlet)
    location = ShopifyInventory.locations[outlet]

    response = ShopifyClient.connect_inventory_location(inventory_item_id, location)

    if ShopifyClient.inventory_item_updated?(response)
      shopify_inventories << ShopifyInventory.new(location: location, inventory: 0)
    else
      shopify_variant = ShopifyClient.get_variant(variant_id)
      if shopify_variant.blank?
        Airbrake.notify("Could not CONNECT #{outlet.to_s.upcase} inventory location for DELETED Shopify Product: #{product_id}. Deleting from app")
        self.class.destroy(id)
      else
        Airbrake.notify("Could not CONNECT #{outlet.to_s.upcase} inventory location for EXISTING Shopify Product: #{product_id}")
      end
    end
  rescue StandardError
    Airbrake.notify("There was an error CONNECTING #{outlet.to_s.upcase} inventory location for Product: #{product_id}")
  end

  def inventory_at_location(location = 'Mollusk SF')
    shopify_inventories.find_by(location: location)
  end

  def inventory_item
    ShopifyClient.get_inventory_item(inventory_item_id)
  end

  def full_title
    if variant_title.present? && variant_title != 'Default Title'
      "#{title} - #{variant_title}"
    else
      title
    end
  end

  def third_party?
    tags.find { |tag| tag.strip.downcase == '3rdparty' }.present?
  end

  def sale?
    tags.find { |tag| tag.strip.downcase == 'sale' }.present?
  end

  def third_party_or_sale?
    tags.find { |tag| %w[3rdparty sale].include?(tag.strip.downcase) }.present?
  end

  def sort_key
    "#{product_type}#{full_title}"
  end

  def get_cost
    return cost if cost.present?

    new_cost = ShopifyClient.get_cost(variant_id)

    if new_cost.present?
      update(cost: new_cost)
      new_cost
    else
      Airbrake.notify("COST MISSING: Item in shopify order { barcode: #{barcode}, product_id: #{shopify_product_id}, variant_id: #{variant_id} }")
      0.0
    end
  end

  def order_locations(all_locations = ShopifyInventory::STORE_CITIES.keys)
    return [] if tags.find { |tag| tag.strip.downcase == 'hold-all-stores' }.present?

    all_locations -= ['Mollusk SF'] if tags.find { |tag| tag.strip.downcase == 'hold-sf' }.present?
    all_locations -= ['Mollusk SB'] if tags.find { |tag| tag.strip.downcase == 'hold-sb' }.present?
    all_locations -= ['Mollusk VB'] if tags.find { |tag| tag.strip.downcase == 'hold-vb' }.present?

    all_locations
  end

  def link
    "https://mollusksurf.myshopify.com/admin/products/#{shopify_product_id}/variants/#{variant_id}"
  end
end

# == Schema Information
#
# Table name: shopify_data
#
#  id                     :bigint(8)        not null, primary key
#  barcode                :string
#  compare_at_price       :string
#  cost                   :float            default(0.0)
#  fulfillment_service    :string
#  grams                  :integer
#  handle                 :string
#  inventory_management   :string
#  inventory_policy       :string
#  inventory_quantity     :integer
#  old_inventory_quantity :integer
#  option1                :string
#  option2                :string
#  option3                :string
#  price                  :string
#  product_type           :string
#  requires_shipping      :string
#  shopify_created_at     :datetime
#  sku                    :string
#  tags                   :text
#  title                  :string
#  variant_created_at     :datetime
#  variant_title          :string
#  vendor                 :string
#  weight                 :float
#  weight_unit            :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  inventory_item_id      :bigint(8)
#  product_id             :integer
#  shopify_product_id     :bigint(8)
#  variant_id             :bigint(8)
#

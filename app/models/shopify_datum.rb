# frozen_string_literal: true

class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true
  has_many :shopify_inventories, dependent: :destroy

  scope :with_warehouse, -> { joins(:shopify_inventories).merge(ShopifyInventory.with_warehouse) }

  def inventory_at_location(location = 'Mollusk SF')
    shopify_inventories.find_by(location: location)
  end

  def inventory_item
    ShopifyClient.get_inventory_item(inventory_item_id)
  end

  def full_title
    "#{title} - #{variant_title}"
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

  def get_cost
    vend_product = product.vend_datum
    if vend_product.present?
      vend_product.supply_price.to_f
    else
      cost = inventory_item['cost']
      return cost unless cost.blank?

      Airbrake.notify("COST MISSING: Item in shopify order, shopify product exists without Vend Product and Cost is missing in Shopify: { barcode: #{barcode}, product_id: #{shopify_product_id}, variant_id: #{variant_id} }")
      0.0
    end
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

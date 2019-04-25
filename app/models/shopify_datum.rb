class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true
  has_many :shopify_inventories

  enum store: {
    retail: 0,
    wholesale: 1
  }

  scope :retail, lambda {
    where(store: :retail)
  }

  scope :wholesale, lambda {
    where(store: :wholesale)
  }

  def inventory_at_location(location = 'Mollusk SF')
    shopify_inventories.find_by(location: location)&.inventory
  end

  def full_title
    "#{title} - #{variant_title}"
  end

  def third_party?
    tags.detect { |tag| tag.strip.downcase == '3rdparty' }.present?
  end

  def sale?
    tags.detect { |tag| tag.strip.downcase == 'sale' }.present?
  end

  def third_party_or_sale?
    tags.detect { |tag| %w[3rdparty sale].include?(tag.strip.downcase) }.present?
  end
end

# == Schema Information
#
# Table name: shopify_data
#
#  id                     :bigint(8)        not null, primary key
#  barcode                :string
#  compare_at_price       :string
#  fulfillment_service    :string
#  grams                  :integer
#  handle                 :string
#  inventory              :integer
#  inventory_management   :string
#  inventory_policy       :string
#  inventory_quantity     :integer
#  old_inventory_quantity :integer
#  price                  :string
#  product_type           :string
#  requires_shipping      :string
#  shopify_created_at     :datetime
#  sku                    :string
#  store                  :integer
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

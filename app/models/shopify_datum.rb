class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true

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

  def self.save_variants(variants, store)
    variants.each do |product_data|
      product_data[:store] = store
      product = VendDatum.find_by_sku(product_data[:sku]).try(:product)
      product.create_shopify_datum(product_data) if product.present?
    end
  end

  def full_title
    "#{title} - #{variant_title}"
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

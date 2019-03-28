class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true

  def self.save_variants(variants)
    variants.each do |product_data|
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
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  handle                 :string
#  product_type           :string
#  tags                   :text
#  title                  :string
#  vendor                 :string
#  barcode                :string
#  compare_at_price       :string
#  fulfillment_service    :string
#  grams                  :integer
#  inventory_item_id      :bigint(8)
#  inventory_management   :string
#  inventory_policy       :string
#  inventory_quantity     :integer
#  old_inventory_quantity :integer
#  price                  :string
#  shopify_product_id     :bigint(8)
#  variant_id             :bigint(8)
#  requires_shipping      :string
#  sku                    :string
#  variant_title          :string
#  weight                 :float
#  weight_unit            :string
#  variant_created_at     :datetime
#  shopify_created_at     :datetime
#  product_id             :integer
#  inventory              :integer
#

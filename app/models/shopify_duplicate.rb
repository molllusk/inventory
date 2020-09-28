class ShopifyDuplicate < ApplicationRecord
  belongs_to :product, optional: true

  def original_shopify_link
    "https://mollusksurf.myshopify.com/admin/products/#{original_shopify_product_id}/variants/#{original_variant_id}"
  end

  def duplicate_shopify_link
    "https://mollusksurf.myshopify.com/admin/products/#{duplicate_shopify_product_id}/variants/#{duplicate_variant_id}"
  end
end

# == Schema Information
#
# Table name: shopify_duplicates
#
#  id                           :bigint(8)        not null, primary key
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  duplicate_shopify_product_id :bigint(8)
#  duplicate_variant_id         :bigint(8)
#  original_shopify_product_id  :bigint(8)
#  original_variant_id          :bigint(8)
#  product_id                   :integer
#

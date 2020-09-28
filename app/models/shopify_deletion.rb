class ShopifyDeletion < ApplicationRecord
  belongs_to :product, optional: true

  def deleted_shopify_link
    "https://mollusksurf.myshopify.com/admin/products/#{deleted_shopify_product_id}/variants/#{deleted_variant_id}"
  end

  def new_shopify_link
    "https://mollusksurf.myshopify.com/admin/products/#{new_shopify_product_id}/variants/#{new_variant_id}"
  end
end

# == Schema Information
#
# Table name: shopify_deletions
#
#  id                         :bigint(8)        not null, primary key
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  deleted_shopify_product_id :bigint(8)
#  deleted_variant_id         :bigint(8)
#  new_shopify_product_id     :bigint(8)
#  new_variant_id             :bigint(8)
#  product_id                 :integer
#

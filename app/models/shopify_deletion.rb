class ShopifyDeletion < ApplicationRecord
  belongs_to :product, optional: true
end

# == Schema Information
#
# Table name: shopify_deletions
#
#  id                 :bigint(8)        not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  deleted_variant_id :bigint(8)
#  new_variant_id     :bigint(8)
#  product_id         :integer
#

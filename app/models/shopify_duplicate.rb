class ShopifyDuplicate < ApplicationRecord
  belongs_to :product, optional: true
end

# == Schema Information
#
# Table name: shopify_duplicates
#
#  id                   :bigint(8)        not null, primary key
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  duplicate_variant_id :bigint(8)
#  original_variant_id  :bigint(8)
#  product_id           :integer
#

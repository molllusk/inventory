require 'test_helper'

class ShopifyDeletionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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

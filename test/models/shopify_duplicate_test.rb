require 'test_helper'

class ShopifyDuplicateTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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

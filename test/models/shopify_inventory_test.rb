# == Schema Information
#
# Table name: shopify_inventories
#
#  id                 :bigint(8)        not null, primary key
#  inventory          :integer
#  inventory_location :integer
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  shopify_datum_id   :integer
#

require 'test_helper'

class ShopifyInventoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# frozen_string_literal: true

require 'test_helper'

class ShopifyDatumTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
#  inventory_management   :string
#  inventory_policy       :string
#  inventory_quantity     :integer
#  old_inventory_quantity :integer
#  option1                :string
#  option2                :string
#  option3                :string
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

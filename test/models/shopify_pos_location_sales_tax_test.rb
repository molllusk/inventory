# frozen_string_literal: true

require 'test_helper'

class ShopifyPosLocationSalesTaxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: shopify_pos_location_sales_taxes
#
#  id                       :bigint(8)        not null, primary key
#  amount                   :float            default(0.0)
#  location                 :bigint(8)
#  sales_tax                :float            default(0.0)
#  shipping                 :float            default(0.0)
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  shopify_pos_sales_tax_id :integer
#

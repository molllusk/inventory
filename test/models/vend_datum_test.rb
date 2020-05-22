# frozen_string_literal: true

require 'test_helper'

class VendDatumTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end

# == Schema Information
#
# Table name: vend_data
#
#  id                :bigint(8)        not null, primary key
#  active            :boolean
#  brand             :string
#  categories        :text
#  handle            :string
#  has_inventory     :boolean
#  has_variants      :boolean
#  is_active         :boolean
#  name              :string
#  sku               :string
#  supplier          :string
#  supply_price      :string
#  tag_ids           :text
#  variant_count     :string
#  variant_name      :string
#  variant_options   :text
#  vend_created_at   :datetime
#  vend_deleted_at   :datetime
#  vend_type         :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  brand_id          :string
#  product_id        :integer
#  product_type_id   :string
#  supplier_id       :string
#  variant_parent_id :string
#  vend_id           :string
#

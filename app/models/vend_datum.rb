class VendDatum < ApplicationRecord
  serialize :brand, Hash
  serialize :supplier, Hash
  serialize :vend_type, Hash
  serialize :variant_options, Array
  serialize :tag_ids, Array
  serialize :categories, Array

  belongs_to :product
  has_many :vend_inventories, dependent: :destroy

  def sf_inventory
    inventory.to_i < 0 ? 0 : inventory.to_i
  end
end

# == Schema Information
#
# Table name: vend_data
#
#  id                :bigint(8)        not null, primary key
#  active            :boolean
#  brand             :string
#  brand_id          :string
#  categories        :text
#  vend_created_at   :datetime
#  vend_deleted_at   :datetime
#  handle            :string
#  has_inventory     :boolean
#  has_variants      :boolean
#  vend_id           :string
#  is_active         :boolean
#  name              :string
#  product_type_id   :string
#  sku               :string
#  supplier          :string
#  supplier_id       :string
#  supply_price      :string
#  tag_ids           :text
#  vend_type         :text
#  variant_count     :string
#  variant_name      :string
#  variant_options   :text
#  variant_parent_id :string
#  product_id        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  inventory         :integer
#

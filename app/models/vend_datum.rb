class VendDatum < ApplicationRecord
  serialize :brand, Hash
  serialize :supplier, Hash
  serialize :vend_type, Hash
  serialize :variant_options, Array
  serialize :tag_ids, Array
  serialize :categories, Array

  belongs_to :product

end

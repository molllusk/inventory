class ShopifyDatum < ApplicationRecord
  serialize :tags, Array

  belongs_to :product, optional: true

  def full_title
    "#{title} - #{variant_title}"
  end
end

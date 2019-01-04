class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy

  def has_shopify?
    shopify_datum.present?
  end
end

class Product < ApplicationRecord
  has_one :vend_datum
  has_one :shopify_datum
end

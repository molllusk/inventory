class VendSalesTax < ApplicationRecord
  has_many :vend_sales_receipt_sales

  RENTAL_IDS = %w[
    b8ca3a6e-723e-11e4-efc6-64565067889f
    31eb0866-e73e-11e5-e556-0c7a3a5958c3
    6991652c-16f4-11e2-b195-4040782fde00
    0adfd74a-153e-11e9-fa42-51ae7eb59c62
  ]
end

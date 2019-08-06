class VendSalesTax < ApplicationRecord
  belongs_to :daily_vend_sale
  has_many :vend_location_sales_taxes, dependent: :destroy

  RENTAL_IDS = %w[
    b8ca3a6e-723e-11e4-efc6-64565067889f
    31eb0866-e73e-11e5-e556-0c7a3a5958c3
    6991652c-16f4-11e2-b195-4040782fde00
    0adfd74a-153e-11e9-fa42-51ae7eb59c62
  ]

  def sales
    daily_vend_sale.vend_sales_receipt_sales
  end

  def date
    daily_vend_sale.date
  end

  def taxes_by_location
    taxes = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    sales.each do |sale|
      taxes[sale.outlet_id][:amount] += sale.product_sales + sale.shipping - sale.rentals
      taxes[sale.outlet_id][:shipping] += sale.shipping
      taxes[sale.outlet_id][:sales_tax] += sale.sales_tax
    end

    taxes
  end

  def create_location_taxes
    taxes_by_location.each do |outlet_id, location_tax|
      location_tax[:outlet_id] = outlet_id
      VendSalesTax.vend_location_sales_taxes << VendLocationSalesTax.build(location_tax)
    end
  end
end

# transaction_id = sf{+1}
# transaction_date  = “{2015-05-14T00:00:00Z}"
# provider = “San Francisco Store”
# to_country =  “US”
# to_zip = “94122”
# to_state = “CA”
# amount = total “Product Sales” of daily orders + “Shipping”, excluding sales tax and rentals (see section below)
# shipping = total amount of “Shipping” for daily orders
# Sales_tax = total amount of “Sales Tax” collected for orders

# == Schema Information
#
# Table name: vend_sales_taxes
#
#  id                 :bigint(8)        not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  daily_vend_sale_id :integer
#

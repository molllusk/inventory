class VendSalesTax < ApplicationRecord
  belongs_to :daily_vend_sale
  has_many :vend_location_sales_taxes, dependent: :destroy

  scope :last_month, lambda {
    joins(:daily_vend_sale).where('daily_vend_sales.date >= ? AND daily_vend_sales.date <= ?', 1.month.ago.beginning_of_month, 1.month.ago.end_of_month)
  }

  RENTAL_IDS = %w[
    b8ca3a6e-723e-11e4-efc6-64565067889f
    31eb0866-e73e-11e5-e556-0c7a3a5958c3
    6991652c-16f4-11e2-b195-4040782fde00
    0adfd74a-153e-11e9-fa42-51ae7eb59c62
    0adfd74a-153e-11e9-fa42-51ae7ec84c09
  ]

  def self.csv_file_name
    "Vend_sales_tax_#{1.month.ago.strftime("%B")}.csv"
  end

  def self.csv
    dates = last_month
    CSV.open(csv_file_name, 'w', headers: [:date] + VendLocationSalesTaxes::CSV_HEADERS, write_headers: true) do |new_csv|
      dates.each do |day|
        date.vend_location_sales_taxes.each do |location|
          new_csv << [day.date] + VendLocationSalesTaxes::CSV_HEADERS.map { |header| location.taxjar_params[header] }
        end
      end
    end
  end

  def sales
    daily_vend_sale.vend_sales_receipt_sales
  end

  def date
    daily_vend_sale.date
  end

  def taxes_by_location
    taxes = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    sales.each do |sale|
      taxes[sale.outlet_id][:amount] += sale.product_sales + sale.shipping + sale.discount_sales - sale.discount - sale.rentals
      taxes[sale.outlet_id][:shipping] += sale.shipping
      taxes[sale.outlet_id][:sales_tax] += sale.sales_tax
    end

    taxes
  end

  def create_location_taxes
    taxes_by_location.each do |outlet_id, location_tax|
      location_tax[:outlet_id] = outlet_id
      vend_location_sales_taxes.create(location_tax)
    end
  end

  def post_to_taxjar
    if sales.present?
      vend_location_sales_taxes.each do |location_tax|
        location_tax.post_to_taxjar
      end
    end
  end
end

# == Schema Information
#
# Table name: vend_sales_taxes
#
#  id                 :bigint(8)        not null, primary key
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  daily_vend_sale_id :integer
#

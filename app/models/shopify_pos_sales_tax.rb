class ShopifyPosSalesTax < ApplicationRecord
  belongs_to :daily_shopify_pos_sale
  has_many :shopify_pos_location_sales_taxes, dependent: :destroy

  # maybe have this take an argument of number of months ago, see self.csv below
  scope :last_month, lambda {
    joins(:daily_shopify_pos_sale).where('daily_shopify_pos_sales.date >= ? AND daily_shopify_pos_sales.date <= ?', 1.month.ago.beginning_of_month, 1.month.ago.end_of_month)
  }

  def self.csv_file_name
    "Shopify_POS_sales_tax_#{1.month.ago.strftime('%B')}.csv"
  end

  # maybe have this take an argument of number of months ago and pass that to the 'last_month' scope (default 1)
  # to regenerate prior months when needed
  def self.csv
    CSV.generate(headers: ShopifyPosLocationSalesTax::CSV_HEADERS, write_headers: true) do |new_csv|
      ShopifyPosSalesTax.last_month.each do |day|
        day.shopify_pos_location_sales_taxes.each do |location|
          new_csv << location.csv_row
        end
      end
    end
  end

  def sales
    daily_shopify_pos_sale.shopify_pos_sales_receipt_sales
  end

  def date
    daily_shopify_pos_sale.date
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
      shopify_pos_location_sales_taxes.create(location_tax)
    end
  end
end

# == Schema Information
#
# Table name: shopify_pos_sales_taxes
#
#  id                        :bigint(8)        not null, primary key
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  daily_shopify_pos_sale_id :integer
#

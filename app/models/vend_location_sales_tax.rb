# frozen_string_literal: true

class VendLocationSalesTax < ApplicationRecord
  belongs_to :vend_sales_tax

  CSV_HEADERS = %i[
    amount
    shipping
    sales_tax
    id
    provider
    to_zip
    to_state
    to_country
    transaction_date
  ].freeze

  ZIPS_BY_LOCATION = {
    'San Francisco' => '94122',
    'Santa Barbara' => '93101',
    'Silver Lake' => '90026',
    'Venice Beach' => '90291'
  }.freeze

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def transaction_date
    vend_sales_tax.date
  end

  def provider
    "#{outlet_name.split(/\s+/).join('-')}-Store"
  end

  def to_zip
    ZIPS_BY_LOCATION[outlet_name]
  end

  def to_state
    'CA'
  end

  def to_country
    'US'
  end

  def csv_row
    data = {
      amount: amount,
      shipping: shipping,
      sales_tax: sales_tax,
      id: id,
      provider: provider,
      to_zip: to_zip,
      to_state: to_state,
      to_country: to_country,
      transaction_date: transaction_date.strftime('%Y/%m/%d')
    }

    CSV_HEADERS.map { |header| data[header] }
  end
end

# == Schema Information
#
# Table name: vend_location_sales_taxes
#
#  id                :bigint(8)        not null, primary key
#  amount            :float            default(0.0)
#  sales_tax         :float            default(0.0)
#  shipping          :float            default(0.0)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  outlet_id         :string
#  vend_sales_tax_id :integer
#

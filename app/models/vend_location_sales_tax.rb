class VendLocationSalesTax < ApplicationRecord
  belongs_to :vend_sales_tax

  CSV_HEADERS = [
    :amount,
    :shipping,
    :sales_tax,
    :transaction_id,
    :provider,
    :to_zip,
    :to_state,
    :to_country,
    :transaction_date
  ]

  TRANSACTION_ID_PREFIX = {
    'San Francisco' => 'sf',
    'Venice Beach' => 'vb',
    'Silver Lake' => 'sl'
  }

  ZIPS_BY_LOCATION = {
    'San Francisco' => '94122',
    'Venice Beach' => '90291',
    'Silver Lake' => '90026'
  }

  def outlet_name
    VendClient::OUTLET_NAMES_BY_ID[outlet_id]
  end

  def transaction_id
    "#{TRANSACTION_ID_PREFIX[outlet_name]}#{id}"
  end

  def transaction_date
    vend_sales_tax.date
  end

  def provider
    outlet_name.split(/\s+/).join('-') + '-Store'
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

  def taxjar_params
    {
      amount: amount,
      shipping: shipping,
      sales_tax: sales_tax,
      transaction_id: transaction_id,
      provider: provider,
      to_zip: to_zip,
      to_state: to_state,
      to_country: to_country,
      transaction_date: transaction_date.strftime("%Y/%m/%d")
    }
  end

  def post_to_taxjar
    begin
      order = TaxjarClient.connection.create_order(taxjar_params)
      update_attribute(:taxjar_id, order.transaction_id)
    rescue
      Airbrake.notify($!)
    end
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
#  taxjar_id         :string
#  vend_sales_tax_id :integer
#

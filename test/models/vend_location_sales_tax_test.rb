require 'test_helper'

class VendLocationSalesTaxTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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

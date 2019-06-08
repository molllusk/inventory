class ShopifySalesReceipt < ApplicationRecord
  filterrific(
    default_filter_params: { sorted_by: 'date_desc' },
    available_filters: [ :sorted_by ]
  )

  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'

    case sort_option.to_s
    when /^date_/
      order("shopify_sales_receipts.date #{ direction }")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }
end

# == Schema Information
#
# Table name: shopify_sales_receipts
#
#  id                 :bigint(8)        not null, primary key
#  date               :datetime
#  discount           :float            default(0.0)
#  gift_card_payments :float            default(0.0)
#  gift_card_sales    :float            default(0.0)
#  paypal_payments    :float            default(0.0)
#  product_sales      :float            default(0.0)
#  sales_tax          :float            default(0.0)
#  shipping           :float            default(0.0)
#  shopify_payments   :float            default(0.0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

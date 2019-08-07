class FluidInventoryUpdate < ApplicationRecord
  belongs_to :product

  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: [
      :search_query,
      :sorted_by
    ]
  )

  scope :search_query, lambda { |query|
    # Matches using LIKE, automatically appends '%' to each term.
    # LIKE is case INsensitive with MySQL, however it is case
    # sensitive with PostGreSQL. To make it work in both worlds,
    # we downcase everything.
    return nil if query.blank?

    terms = query.to_s.downcase.split(/\s+/)

    terms = terms.map { |e|
      ('%' + e + '%').gsub(/%+/, '%')
    }

    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conds = 4

    product_ids = Product.joins(:shopify_data, :vend_datum).where(
      terms.map { |term|
        "(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ? OR LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    ).pluck(:id)

    where(product_id: product_ids)
  }

  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'

    case sort_option.to_s
    when /^created_at_/
      order("fluid_inventory_updates.created_at #{ direction }")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }

  def retail_success?
    new_retail_qty == (prior_retail_qty + adjustment)
  end

  def wholesale_success?
    new_wholesale_qty == (prior_wholesale_qty - adjustment)
  end

  def success?
    retail_success? && wholesale_success?
  end
end

# == Schema Information
#
# Table name: fluid_inventory_updates
#
#  id                  :bigint(8)        not null, primary key
#  adjustment          :integer
#  new_retail_qty      :integer
#  new_wholesale_qty   :integer
#  prior_retail_qty    :integer
#  prior_wholesale_qty :integer
#  threshold           :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  product_id          :integer
#


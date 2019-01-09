class InventoryUpdate < ApplicationRecord
  belongs_to :product

  after_create :run_update

  filterrific(
     available_filters: [
       :search_query,
     ]
   )

  scope :search_query, lambda { |query|
    # Matches using LIKE, automatically appends '%' to each term.
    # LIKE is case INsensitive with MySQL, however it is case
    # sensitive with PostGreSQL. To make it work in both worlds,
    # we downcase everything.
    return nil if query.blank?

    terms = query.downcase.split(/\s+/)

    terms = terms.map { |e|
      ('%' + e + '%').gsub(/%+/, '%')
    }

    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conds = 4

    product_ids = Product.joins(:shopify_datum, :vend_datum).where(
      terms.map { |term|
        "(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ? OR LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    ).pluck(:id)

    where(product_id: product_ids)
  }

  def inventory_item_id
    product.shopify_datum.inventory_item_id
  end

  private
    def run_update
      response = ShopifyClient.adjust_inventory(inventory_item_id, adjustment)
      p response
      product.shopify_datum.update_attribute(:inventory, response['inventory_level']['available'])
    end
end

# == Schema Information
#
# Table name: inventory_updates
#
#  id         :bigint(8)        not null, primary key
#  product_id :integer
#  adjustment :integer
#  prior_qty  :integer
#  vend_qty   :integer
#

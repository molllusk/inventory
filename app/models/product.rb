class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy

  CSV_HEADERS = %w(id name vend shopify difference url)

  filterrific(
     available_filters: [
       :search_query,
     ]
   )

  scope :search_query, lambda { |query|
    # Searches the students table on the 'first_name' and 'last_name' columns.
    # Matches using LIKE, automatically appends '%' to each term.
    # LIKE is case INsensitive with MySQL, however it is case
    # sensitive with PostGreSQL. To make it work in both worlds,
    # we downcase everything.
    return nil if query.blank?

    # condition query, parse into individual keywords
    terms = query.downcase.split(/\s+/)

    # replace "*" with "%" for wildcard searches,
    # append '%', remove duplicate '%'s
    terms = terms.map { |e|
      ('%' + e + '%').gsub(/%+/, '%')
    }

    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conds = 2

    shopify_matches = ShopifyDatum.where(
        terms.map { |term|
          "(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ?)"
        }.join(' AND '),
        *terms.map { |e| [e] * num_or_conds }.flatten
      ).pluck(:product_id)

    vend_matches = VendDatum.where(
        terms.map { |term|
          "(LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)"
        }.join(' AND '),
        *terms.map { |e| [e] * num_or_conds }.flatten
      ).pluck(:product_id)

    where(id: (shopify_matches + vend_matches).uniq)
  }

  def self.inventory_check
    csv = inventory_check_csv
    ApplicationMailer.inventory_check(csv).deliver if CSV.parse(csv).count > 1
  end

  def self.inventory_check_csv
    CSV.generate(headers: CSV_HEADERS, write_headers: true) do |csv|
      find_each do |product|
        vend_inventory = product.vend_datum.inventory.to_i
        shopify_inventory = product.shopify_datum.inventory.to_i
        csv << [
          product.id,
          "#{product.vend_datum.name} #{product.vend_datum.variant_name}".strip,
          vend_inventory,
          shopify_inventory,
          vend_inventory - shopify_inventory,
          "https://mollusk.herokuapp.com/products/#{product.id}"
        ] if vend_inventory != shopify_inventory
      end
    end
  end

  def has_shopify?
    shopify_datum.present?
  end
end

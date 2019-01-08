class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy

  CSV_HEADERS = %w(id name vend shopify difference price url)

  filterrific(
     available_filters: [
       :search_query,
     ]
   )

  scope :third_party, lambda {
    where("LOWER(shopify_data.tags) like ?", "%3rdparty%").joins(:shopify_datum)
  }

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

    joins(:shopify_datum, :vend_datum).where(
      terms.map { |term|
        "(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ? OR LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  def self.inventory_check
    csv = inventory_check_csv
    ApplicationMailer.inventory_check(csv).deliver if CSV.parse(csv).count > 1
  end

  def self.inventory_check_csv
    CSV.generate(headers: CSV_HEADERS, write_headers: true) do |csv|
      third_party.find_each do |product|
        vend_inventory = product.vend_datum.inventory.to_i
        shopify_inventory = product.shopify_datum.inventory.to_i
        csv << [
          product.id,
          "#{product.vend_datum.name} #{product.vend_datum.variant_name}".strip,
          vend_inventory,
          shopify_inventory,
          vend_inventory - shopify_inventory,
          product.shopify_datum.price,
          "https://mollusk.herokuapp.com/products/#{product.id}"
        ] if vend_inventory != shopify_inventory
      end
    end
  end

  def has_shopify?
    shopify_datum.present?
  end
end

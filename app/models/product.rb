class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy
  has_many :inventory_updates, dependent: :destroy

  CSV_HEADERS = %w(
    id
    name
    variant
    vend
    shopify
    difference
    price
    update?
    3rdParty
    sale
    url
  )

  filterrific(
     available_filters: [
       :search_query,
     ]
   )

  scope :third_party, lambda {
    where('LOWER(shopify_data.tags) like ?', '%3rdparty%').joins(:shopify_datum)
  }

  scope :sale, lambda {
    where('LOWER(shopify_data.tags) like ?', '%sale%').joins(:shopify_datum)
  }

  scope :third_party_or_sale, lambda {
    where('LOWER(shopify_data.tags) like ? OR LOWER(shopify_data.tags) like ?', '%3rdparty%', '%sale%').joins(:shopify_datum)
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
    csv = inventory_csv
    ApplicationMailer.inventory_check(csv).deliver if CSV.parse(csv).count > 1
  end

  def self.inventory_csv(make_updates = false)
    CSV.generate(headers: CSV_HEADERS, write_headers: true) do |csv|
      third_party_or_sale.find_each do |product|
        if product.vend_inventory != product.shopify_inventory
          csv << product.inventory_csv_row
          product.adjust_inventory if make_updates && product.update_shopify_inventory?
        end
      end
    end
  end

  def adjust_inventory
    create_inventory_adjustment(vend_qty: vend_inventory, prior_qty: shopify_inventory, adjustment: inventory_adjustment)
  end

  def inventory_csv_row
    [
      id,
      vend_datum.name,
      vend_datum.variant_name,
      vend_inventory,
      shopify_inventory,
      inventory_adjustment,
      shopify_datum.price,
      update_shopify_inventory?,
      third_party?,
      sale?,
      "https://mollusk.herokuapp.com/products/#{id}"
    ]
  end

  def shopify_inventory
    shopify_datum.inventory.to_i
  end

  def vend_inventory
    vend_datum.inventory.to_i
  end

  def update_shopify_inventory?
    (third_party? || sale?) && !(vend_inventory < 0 && shopify_inventory.zero?)
  end

  def inventory_adjustment
    vend_inventory - shopify_inventory
  end

  def third_party?
    shopify_datum.tags.detect { |tag| tag.strip.downcase == '3rdparty' }.present?
  end

  def sale?
    shopify_datum.tags.detect { |tag| tag.strip.downcase == 'sale' }.present?
  end
end

# == Schema Information
#
# Table name: products
#
#  id         :bigint(8)        not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# frozen_string_literal: true

class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :shopify_duplicates, dependent: :destroy
  has_many :shopify_deletions, dependent: :destroy

  LOCATION_NAMES_BY_CODE = {
    sf: 'San Francisco',
    sb: 'Santa Barbara',
    sl: 'Silver Lake',
    vb: 'Venice Beach'
  }.freeze

  CLOSED_LOCATIONS = ['Silver Lake'].freeze

  ORDER_LOCATIONS = LOCATION_NAMES_BY_CODE.values - CLOSED_LOCATIONS + ['Fill']

  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: %i[
      search_query
      sorted_by
    ]
  )

  scope :third_party, lambda {
    where('LOWER(shopify_data.tags) like ?', '%3rdparty%')
      .joins(:shopify_datum)
  }

  scope :sale, lambda {
    where('LOWER(shopify_data.tags) like ?', '%sale%')
      .joins(:shopify_datum)
  }

  scope :third_party_or_sale, lambda {
    where('LOWER(shopify_data.tags) like ? OR LOWER(shopify_data.tags) like ?', '%3rdparty%', '%sale%')
      .joins(:shopify_datum)
  }

  scope :with_shopify, lambda {
    joins(:shopify_datum).distinct
  }

  scope :search_query, lambda { |query|
    # Matches using LIKE, automatically appends '%' to each term.
    # LIKE is case INsensitive with MySQL, however it is case
    # sensitive with PostGreSQL. To make it work in both worlds,
    # we downcase everything.
    return nil if query.blank?

    terms = query.to_s.downcase.split(/\s+/)

    terms = terms.map do |e|
      "%#{e}%".gsub(/%+/, '%')
    end

    # configure number of OR conditions for provision
    # of interpolation arguments. Adjust this if you
    # change the number of OR conditions.
    num_or_conds = 4

    joins(:shopify_datum, :vend_datum).where(
      terms.map do |_term|
        '(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ? OR LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)'
      end.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = sort_option =~ /desc$/ ? 'desc' : 'asc'

    case sort_option.to_s
    when /^created_at_/
      order("products.created_at #{direction}")
    else
      raise(ArgumentError, "Invalid sort option: #{sort_option.inspect}")
    end
  }

  def self.daily_order_inventory_levels
    @daily_order_inventory_levels ||= get_daily_order_inventory_levels
  end

  def self.get_release_schedule
    GoogleClient.sheet_values(GoogleClient::RELEASE_SCHEDULE, "John's Release Schedule").sort_by { |row| row['Category'] }
  end

  def self.release_schedule
    @release_schedule ||= get_release_schedule
  end

  def self.get_inventory_levels(fill_key = 'WH Fill')
    levels = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL).sort_by { |row| row['Category'] }
    levels_by_type_and_size = Hash.new { |hash, key| hash[key] = {} }
    levels.each do |level|
      levels_by_type_and_size[level['Category'].to_s.strip.downcase][level['Size'].to_s.strip.downcase] = level[fill_key].to_i
    end
    levels_by_type_and_size
  end

  def self.get_daily_order_inventory_levels
    levels = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL).sort_by { |row| row['Category'] }
    levels_by_type_and_size = Hash.new { |types, type_key| types[type_key] = Hash.new { |sizes, size_key| sizes[size_key] = {} } }
    levels.each do |level|
      ORDER_LOCATIONS.each do |location|
        levels_by_type_and_size[level['Category'].to_s.strip.downcase][level['Size'].to_s.strip.downcase][location] = level[location]
      end
    end
    levels_by_type_and_size
  end

  def self.update_shopify_costs(inventory_item_ids = nil)
    inventory_item_ids ||= ShopifyDatum.pluck(:inventory_item_id)

    inventory_items = ShopifyClient.get_inventory_items(inventory_item_ids)

    inventory_items.each do |inventory_item|
      shopify_variant = ShopifyDatum.find_by(inventory_item_id: inventory_item['id'])
      next if shopify_variant.cost.to_f == inventory_item['cost'].to_f

      shopify_variant.update_attribute(:cost, inventory_item['cost'])
    end
  end

  def self.inventory_csv
    CSV.generate(headers: inventory_csv_headers, write_headers: true) do |new_csv|
      with_shopify.find_each do |product|
        new_csv << product.inventory_csv_row
      end
    end
  end

  def self.inventory_csv_headers
    stem = %i[id product variant type size sku barcode handle shopify_tags shopify app supplier_name supply_price]
    stem + ShopifyInventory.active_locations + [:total_inventory] + ShopifyInventory.active_locations.map { |loc| "Inventory Value (#{loc})" }
  end

  def orders_present?(orders)
    orders[shopify_datum&.variant_id].positive?
  end

  def title
    shopify_datum&.full_title
  end

  def barcode
    shopify_datum&.barcode
  end

  def sort_key
    shopify_datum&.sort_key
  end

  def inventory_csv_row_data
    data = {
      id: id,
      product: shopify_datum&.title,
      variant: (shopify_datum&.variant_title).to_s.gsub(/Default(\s+Title)?/i, ''),
      type: shopify_datum&.product_type,
      size: shopify_datum&.option1.to_s.strip.downcase,
      sku: shopify_datum&.sku,
      barcode: shopify_datum&.barcode,
      handle: shopify_datum&.handle,
      shopify_tags: shopify_datum&.tags&.join(', '),
      shopify: shopify_datum&.link,
      app: "https://mollusk.herokuapp.com/products/#{id}",
      supplier_name: shopify_datum&.vendor,
      supply_price: shopify_datum&.cost,
      total_inventory: 0
    }

    if shopify_datum.present?
      shopify_datum.shopify_inventories.exclude_dead_locations.each do |inventory|
        data[inventory.location] = inventory.inventory
        data["Inventory Value (#{inventory.location})"] = shopify_datum&.vendor == 'Consignee' ? 0 : inventory.inventory * shopify_datum.cost.to_f
        data[:total_inventory] += inventory.inventory if ['Shopify Fulfillment Network', 'Mollusk SF'].include?(inventory.location)
      end
    end

    data
  end

  def inventory_csv_row
    data = inventory_csv_row_data
    Product.inventory_csv_headers.map { |header| data[header] }
  end

  def connect_inventory_location(outlet = :sf)
    location = ShopifyInventory.locations["Mollusk #{outlet.to_s.upcase}"]

    response = ShopifyClient.connect_inventory_location(shopify_datum.inventory_item_id, location)
    shopify_datum.shopify_inventories << ShopifyInventory.new(location: location, inventory: 0)

    Airbrake.notify("Could not CONNECT #{outlet.to_s.upcase} inventory location for Product: #{id}") unless ShopifyClient.inventory_item_updated?(response)
  rescue StandardError
    Airbrake.notify("There was an error CONNECTING #{outlet.to_s.upcase} inventory location for Product: #{id}")
  end

  def daily_order_inventory_thresholds
    @daily_order_inventory_thresholds ||= Product.daily_order_inventory_levels[shopify_datum.product_type.to_s.strip.downcase]&.[](shopify_datum.option1.to_s.strip.downcase)
  end

  def shopify_inventory(outlet)
    inventory_location(outlet)&.inventory.to_i
  end

  def missing_inventory_location?(outlet)
    inventory_location(outlet).blank?
  end

  def inventory_location(outlet)
    shopify_datum.shopify_inventories.find_by(location: "Mollusk #{outlet.to_s.upcase}")
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

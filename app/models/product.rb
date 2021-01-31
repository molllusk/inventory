# frozen_string_literal: true

class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy
  has_many :inventory_updates, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :shopify_duplicates, dependent: :destroy
  has_many :shopify_deletions, dependent: :destroy

  LOCATION_NAMES_BY_CODE = {
    sf: 'San Francisco',
    sb: 'Santa Barbara',
    sl: 'Silver Lake',
    vb: 'Venice Beach'
  }.freeze

  CLOSED_LOCATIONS = ['Silver Lake']

  ORDER_LOCATIONS = LOCATION_NAMES_BY_CODE.values - CLOSED_LOCATIONS

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
      ('%' + e + '%').gsub(/%+/, '%')
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

  def self.run_inventory_updates
    orders = ShopifyClient.web_order_quantities_by_variant
    update_inventories(orders)
  end

  def self.update_inventories(orders)
    # We'll make this store.where(sync_inventory: true) make it a scope then
    %i[vb sb].each do |outlet|
      # do not update inventory if any order exists for that variant in any location
      update_entire_store_inventory(orders, outlet)
    end
  end

  def self.update_entire_store_inventory(orders, outlet = :sf)
    with_shopify.find_each do |product|
      # do not update inventory if any order exists for that variant in any location
      product.update_inventory(orders, outlet) if product.vend_datum&.inventory_at_location(LOCATION_NAMES_BY_CODE[outlet]).present?
    end
  end

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

  def self.inventory_csv
    CSV.generate(headers: inventory_csv_headers, write_headers: true) do |new_csv|
      find_each do |product|
        new_csv << product.inventory_csv_row
      end
    end
  end

  def self.inventory_csv_headers
    stem = %i[id product variant type size sku handle shopify_tags vend shopify app]
    stem + ShopifyInventory.locations.keys + VendClient::OUTLET_NAMES_BY_ID.values + [:total_inventory]
  end

  def update_inventory(orders, outlet)
    connect_inventory_location(outlet) if missing_inventory_location?(outlet)
    if update_shopify_inventory?(outlet)
      adjust_inventory(outlet) unless orders_present?(orders)
    end
  end

  def orders_present?(orders)
    orders[shopify_datum&.variant_id].positive?
  end

  def adjust_inventory(outlet)
    adjust_inventory_vend(outlet, inventory_adjustment(outlet))
  end

  def inventory_csv_row_data
    data = {
      id: id,
      product: vend_datum&.name || shopify_datum&.title,
      variant: (shopify_datum&.variant_title || vend_datum&.variant_name).to_s.gsub(/Default(\s+Title)?/i, ''),
      type: vend_datum&.vend_type&.[]('name') || shopify_datum&.product_type,
      size: shopify_datum&.option1.to_s.strip.downcase,
      sku: vend_datum&.sku || shopify_datum&.barcode,
      product_sku: shopify_datum&.sku,
      handle: shopify_datum&.handle,
      shopify_tags: shopify_datum&.tags&.join(', '),
      vend: vend_datum&.link,
      shopify: shopify_datum&.link,
      app: "https://mollusk.herokuapp.com/products/#{id}",
      total_inventory: 0
    }

    if shopify_datum.present?
      shopify_datum.shopify_inventories.exclude_dead_locations.each do |inventory|
        data[inventory.location] = inventory.inventory
        data[:total_inventory] += inventory.inventory if ['Postworks', 'Shopify Fulfillment Network'].include?(inventory.location)
      end
    end

    if vend_datum.present?
      vend_datum.vend_inventories.each do |inventory|
        data[inventory.location] = inventory.inventory
        data[:total_inventory] += inventory.inventory
      end
    end

    data
  end

  def inventory_csv_row
    data = inventory_csv_row_data
    Product.inventory_csv_headers.map { |header| data[header] }
  end

  def adjust_inventory_vend(outlet, quantity)
    location_name = "Mollusk #{outlet.to_s.upcase}"
    location_id = ShopifyInventory.locations[location_name]

    begin
      response = ShopifyClient.adjust_inventory(shopify_datum.inventory_item_id, location_id, quantity)

      if ShopifyClient.inventory_item_updated?(response)
        save_inventory_adjustment_vend(response, quantity, outlet)
      else
        Airbrake.notify("Could not UPDATE #{location_name}:#{location_id} inventory for Product: #{id}, Adjustment: #{quantity} | #{response}")
      end
    rescue StandardError => e
      Airbrake.notify("There was an error UPDATING #{location_name}:#{location_id} inventory for Product: #{id}, Adjustment: #{quantity} | #{e}")
    end
  end

  def save_inventory_adjustment_vend(response, quantity, outlet)
    location_id = response['inventory_level']['location_id']
    shopify_inventory = shopify_datum.inventory_at_location(location_id)
    new_inventory = response['inventory_level']['available']

    InventoryUpdate.create(
      vend_qty: vend_inventory(outlet),
      prior_qty: shopify_inventory.inventory,
      adjustment: quantity,
      product_id: id,
      new_qty: new_inventory,
      location: location_id
    )

    shopify_inventory.update_attribute(:inventory, new_inventory)
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

  def vend_inventory(outlet)
    outlet = LOCATION_NAMES_BY_CODE[outlet]
    inventory = vend_datum.vend_inventories.find_by(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key(outlet))&.inventory.to_i
    inventory.negative? ? 0 : inventory
  end

  def update_shopify_inventory?(outlet)
    shopify_inventory(outlet) != vend_inventory(outlet)
  end

  def inventory_adjustment(outlet)
    vend_inventory(outlet) - shopify_inventory(outlet)
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

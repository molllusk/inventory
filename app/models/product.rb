class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_many :shopify_data, dependent: :destroy
  has_many :inventory_updates, dependent: :destroy
  has_many :fluid_inventory_updates, dependent: :destroy

  filterrific(
    default_filter_params: { sorted_by: 'created_at_desc' },
    available_filters: [
      :search_query,
      :sorted_by
    ]
  )

  scope :third_party, lambda {
    where('shopify_data.store = ? AND LOWER(shopify_data.tags) like ?', ShopifyDatum.stores[:retail], '%3rdparty%')
      .joins(:shopify_data)
  }

  scope :sale, lambda {
    where('shopify_data.store = ? AND LOWER(shopify_data.tags) like ?', ShopifyDatum.stores[:retail], '%sale%')
      .joins(:shopify_data)
  }

  scope :third_party_or_sale, lambda {
    where('shopify_data.store = ? AND (LOWER(shopify_data.tags) like ? OR LOWER(shopify_data.tags) like ?)', ShopifyDatum.stores[:retail], '%3rdparty%', '%sale%')
      .joins(:shopify_data)
  }

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

    joins(:shopify_data, :vend_datum).where(
      terms.map { |term|
        "(LOWER(shopify_data.title) LIKE ? OR LOWER(shopify_data.variant_title) LIKE ? OR LOWER(vend_data.name) LIKE ? OR LOWER(vend_data.variant_name) LIKE ?)"
      }.join(' AND '),
      *terms.map { |e| [e] * num_or_conds }.flatten
    )
  }

  scope :sorted_by, lambda { |sort_option|
    # extract the sort direction from the param value.
    direction = (sort_option =~ /desc$/) ? 'desc' : 'asc'

    case sort_option.to_s
    when /^created_at_/
      order("products.created_at #{ direction }")
    else
      raise(ArgumentError, "Invalid sort option: #{ sort_option.inspect }")
    end
  }

  def self.run_inventory_updates
    retail_orders = ShopifyClient.order_quantities_by_variant
    update_retail_inventories_sf(retail_orders)
    update_fluid_inventories(retail_orders)
  end

  def self.update_retail_inventories_sf(retail_orders)
    third_party_or_sale.find_each do |product|
      # do not update inventory if any order exists for that variant in any location
      if product.update_sf_shopify_inventory?
        product.connect_sf_inventory_location if product.missing_retail_inventory_location?
        product.adjust_sf_retail_inventory unless product.retail_orders_present?(retail_orders)
      end
    end
  end

  def self.update_fluid_inventories(retail_orders)
    Product.find_each do |product|
      if product.has_retail_and_wholesale_shopify?
        # do not update inventory if any order exists for that variant in any location
        product.fluid_inventory unless product.retail_orders_present?(retail_orders)
      end
    end
  end

  def self.fluid_inventory_levels
    @fluid_inventory_levels ||= get_fluid_inventory_levels
  end

  def self.get_release_schedule
    GoogleClient.sheet_values(GoogleClient::RELEASE_SCHEDULE, "John's Release Schedule")
    # comparison ['Handle']
    # date ['Release Date']
  end

  def self.release_schedule
    @release_schedule ||= get_release_schedule
  end

  def self.get_fluid_inventory_levels
    levels = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL)
    levels_by_type_and_size = Hash.new { |hash, key| hash[key] = {} }
    levels.each do |level|
      levels_by_type_and_size[level['Category'].to_s.strip.downcase][level['Size'].to_s.strip.downcase] = level['WH Fill'].to_i
    end
    levels_by_type_and_size
  end

  def self.inventory_csv
    CSV.generate(headers: inventory_csv_headers + ['total_inventory'], write_headers: true) do |new_csv|
      find_each do |product|
        new_csv << product.inventory_csv_row
      end
    end
  end

  def has_retail_and_wholesale_shopify?
    retail_shopify.present? && wholesale_shopify.present?
  end

  def retail_orders_present?(retail_orders)
    retail_orders[retail_shopify&.variant_id].positive?
  end

  def wholesale_orders_present?(wholesale_orders)
    wholesale_orders[wholesale_shopify&.variant_id].positive?
  end

  def adjust_sf_retail_inventory
    adjust_inventory_vend('Mollusk SF', retail_inventory_adjustment)
  end

  def self.inventory_csv_headers
    stem = %i(product variant type sku vend retail_shopify wholesale_shopify app)
    stem + ShopifyInventory::locations.keys + VendClient::OUTLET_NAMES_BY_ID.values
  end

  def inventory_csv_row
    total_inventory = 0

    data = { 
      product: vend_datum&.name || retail_shopify&.title || wholesale_shopify&.title,
      variant: (retail_shopify&.variant_title || wholesale_shopify&.variant_title || vend_datum&.variant_name).to_s.gsub(/Default(\s+Title)?/i, ''),
      type: vend_datum&.vend_type&.[]('name') || retail_shopify&.product_type || wholesale_shopify&.product_type,
      sku: vend_datum&.sku || retail_shopify&.barcode || wholesale_shopify&.barcode,
      vend: vend_datum&.link,
      retail_shopify: retail_shopify&.link,
      wholesale_shopify: wholesale_shopify&.link,
      app: "https://mollusk.herokuapp.com/products/#{id}",
    }
    
    shopify_data.each do |shopify|
      shopify.shopify_inventories.each do |inventory|
        data[inventory.location] = inventory.inventory
        total_inventory += inventory.inventory if ['Jam Warehouse Retail', 'Jam Warehouse Wholesale'].include?(inventory.location)
      end
    end

    if vend_datum.present?
      vend_datum.vend_inventories.each do |inventory|
        data[inventory.location] = inventory.inventory
        total_inventory += inventory.inventory
      end
    end

    Product.inventory_csv_headers.map { |header| data[header] } + [total_inventory]
  end

  def adjust_inventory_vend(location_name, quantity)
    location_id = ShopifyInventory.locations[location_name]
    begin
      response = ShopifyClient.adjust_inventory(retail_shopify.inventory_item_id, location_id, quantity)

      if ShopifyClient.inventory_item_updated?(response)
        save_inventory_adjustment_vend(response, quantity)
      else
        Airbrake.notify("Could not UPDATE SF inventory for Product: #{id}, Adjustment: #{quantity}")
      end
    rescue
      Airbrake.notify("There was an error UPDATING SF inventory for Product: #{id}, Adjustment: #{quantity}")
    end
  end

  def adjust_inventory_fluid(quantity, expected_wholesale_inventory)
    begin
      retail_response = ShopifyClient.adjust_inventory(
        retail_shopify.inventory_item_id,
        ShopifyInventory.locations['Jam Warehouse Retail'],
        quantity
      )
      
      if ShopifyClient.inventory_item_updated?(retail_response)
        begin
          wholesale_response = ShopifyClient.adjust_inventory(
            wholesale_shopify.inventory_item_id,
            ShopifyInventory.locations['Jam Warehouse Wholesale'],
            -quantity,
            :WHOLESALE
          )

          if ShopifyClient.inventory_item_updated?(wholesale_response)
            updated_wholesale_inventory = wholesale_response['inventory_level']['available']
            save_inventory_adjustment_fluid(quantity, retail_response['inventory_level']['available'], updated_wholesale_inventory)

            Airbrake.notify("Fluid Inventory: expected Wholesale qty #{expected_wholesale_inventory} but got #{updated_wholesale_inventory}") unless expected_wholesale_inventory == updated_wholesale_inventory
          else
            Airbrake.notify("Could not UPDATE Wholesale Jam Warehouse inventory after already adjusting Retail inventory for Product: #{id}, Adjustment: #{-quantity}")
          end
        rescue
          Airbrake.notify("There was an error UPDATING Wholesale Jam Warehouse inventory after already adjusting Retail inventory for Product: #{id}, Adjustment: #{-quantity}")
        end
      else
        Airbrake.notify("Could not UPDATE Retail Jam Warehouse inventory for Product: #{id}, Adjustment: #{quantity}")
      end
    rescue
      Airbrake.notify("There was an error UPDATING Retail Jam Warehouse inventory for Product: #{id}, Adjustment: #{quantity}")
    end
  end

  # need to change this
  def save_inventory_adjustment_vend(response, quantity)
    location_id = response['inventory_level']['location_id']
    shopify_inventory = retail_shopify.shopify_inventories.find_by(location: location_id)
    new_inventory = response['inventory_level']['available']

    InventoryUpdate.create(
      vend_qty: vend_datum.sf_inventory,
      prior_qty: shopify_inventory.inventory,
      adjustment: quantity,
      product_id: id,
      new_qty: new_inventory
    )

    shopify_inventory.update_attribute(:inventory, new_inventory)
  end

  def save_inventory_adjustment_fluid(quantity, retail_available, wholesale_available)
    retail_inventory = retail_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Retail')
    wholesale_inventory = wholesale_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Wholesale')

    FluidInventoryUpdate.create(
      prior_wholesale_qty: wholesale_inventory.inventory,
      prior_retail_qty: retail_inventory.inventory,
      threshold: fluid_inventory_threshold,
      adjustment: quantity,
      product_id: id,
      new_wholesale_qty: wholesale_available,
      new_retail_qty: retail_available
    )

    retail_inventory.update_attribute(:inventory, retail_available)
    wholesale_inventory.update_attribute(:inventory, wholesale_available)
  end

  def connect_sf_inventory_location
    begin
      sf_location = ShopifyInventory.locations['Mollusk sf']

      response = ShopifyClient.connect_inventory_location(retail_shopify.inventory_item_id, sf_location)

      Airbrake.notify("Could not CONNECT SF inventory location for Product: #{id}") unless ShopifyClient.inventory_item_updated?(response)
    rescue
      Airbrake.notify("There was an error CONNECTING SF inventory for Product: #{id}")
    end
  end

  def fluid_inventory_threshold
    @fluid_inventory_threshold ||= Product.fluid_inventory_levels[retail_shopify.product_type.to_s.strip.downcase]&.[](retail_shopify.option1.to_s.strip.downcase).to_i
  end

  def fluid_inventory
    if has_retail_and_wholesale_shopify?
      retail_inventory = retail_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Retail')&.inventory
      wholesale_inventory = wholesale_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Wholesale')&.inventory

      if retail_inventory.present?
        if wholesale_inventory.present?
          if fluid_inventory_threshold.present?
            if retail_inventory < fluid_inventory_threshold
              sufficient_wholesale = (fluid_inventory_threshold - retail_inventory) <= wholesale_inventory
              adjustment = sufficient_wholesale ? fluid_inventory_threshold - retail_inventory : wholesale_inventory
              # bails on zero adjustments and negative wholesale inventories
              adjust_inventory_fluid(adjustment, wholesale_inventory - adjustment) unless adjustment < 1
            end
          else
            Airbrake.notify("Missing fluid inventory threshold for Product Type: #{retail_shopify.product_type} Product: #{id}")
          end
        else
          Airbrake.notify("Missing WHOLESALE Jam Inventory for Product: #{id}")
        end
      else
        Airbrake.notify("Missing RETAIL Jam Inventory for Product: #{id}")
      end
    end
  end

  def retail_shopify
    shopify_data.find_by(store: :retail)
  end

  def wholesale_shopify
    shopify_data.find_by(store: :wholesale)
  end

  def shopify_inventory_sf
    retail_shopify.shopify_inventories.find_by(location: 'Mollusk SF')&.inventory.to_i
  end

  def update_sf_shopify_inventory?
    retail_shopify.third_party_or_sale? && shopify_inventory_sf != vend_datum.sf_inventory
  end

  def retail_inventory_adjustment
    vend_datum.sf_inventory - shopify_inventory_sf
  end

  def missing_retail_inventory_location?
    retail_shopify.third_party_or_sale? && retail_shopify.shopify_inventories.find_by(location: 'Mollusk SF').nil?
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

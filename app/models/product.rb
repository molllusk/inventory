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

    terms = query.downcase.split(/\s+/)

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

  def wholesale_shopify
    shopify_data.find_by(store: :wholesale)
  end

  def self.run_inventory_updates
    orders = ShopifyClient.order_quantities_by_variant
    update_retail_inventories_sf(orders)
    # update_fluid_inventories(orders)
  end

  def self.update_retail_inventories_sf(orders)
    third_party_or_sale.find_each do |product|
      # do not update inventory if any order exists for that variant in any location
      if product.update_sf_shopify_inventory? && orders[product.retail_shopify.variant_id].zero?
        product.connect_sf_inventory_location if product.missing_retail_inventory_location?
        product.adjust_sf_retail_inventory
      end
    end
  end

  def self.update_fluid_inventories(orders)
    Product.find_each do |product|
      # do not update inventory if any order exists for that variant in any location
      product.fluid_inventory unless orders[product.retail_shopify.variant_id].positive?
    end
  end

  def adjust_sf_retail_inventory
    adjust_inventory_vend('Mollusk SF', retail_inventory_adjustment)
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

  def adjust_inventory_fluid(quantity)
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
            save_inventory_adjustment_fluid(quantity, retail_response['inventory_level']['available'], wholesale_response['inventory_level']['available'])
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
      response = ShopifyClient.connect_sf_inventory_location(retail_shopify.inventory_item_id)
      Airbrake.notify("Could not CONNECT SF inventory location for Product: #{id}") unless ShopifyClient.inventory_item_updated?(response)
    rescue
      Airbrake.notify("There was an error CONNECTING SF inventory for Product: #{id}")
    end
  end

  def fluid_inventory
    if retail_shopify.present? && wholesale_shopify.present?
      retail_inventory = retail_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Retail')&.inventory
      wholesale_inventory = wholesale_shopify.shopify_inventories.find_by(location: 'Jam Warehouse Wholesale')&.inventory
      threshold = FluidInventoryThreshold.find_by(product_type: retail_shopify.product_type)&.threshold

      if retail_inventory.present?
        if wholesale_inventory.present?
          if threshold.present?
            if retail_inventory < threshold
              sufficient_wholesale = (threshold - retail_inventory) <= wholesale_inventory
              adjustment = sufficient_wholesale ? threshold - retail_inventory : wholesale_inventory
              adjust_inventory_fluid(adjustment)
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

  def shopify_inventory_sf
    retail_shopify.shopify_inventories.find_by(location: 'Mollusk SF')&.inventory.to_i
  end

  def update_sf_shopify_inventory?
    retail_shopify.third_party_or_sale? && shopify_inventory_sf != vend_datum.sf_inventory && !(vend_datum.sf_inventory < 0 && shopify_inventory_sf.zero?)
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

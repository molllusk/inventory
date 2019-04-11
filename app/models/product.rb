class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_many :shopify_data, dependent: :destroy
  has_many :inventory_updates, dependent: :destroy

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

  # WHOLESALE specific
  def wholesale_shopify
    shopify_data.find_by(store: :wholesale)
  end

  # RETAIL specific
  def self.update_retail_inventories_sf
    orders = ShopifyClient.order_quantities_by_variant

    third_party_or_sale.find_each do |product|
      if product.update_sf_shopify_inventory? && orders[product.retail_shopify.variant_id] === 0
        product.connect_sf_inventory_location if product.missing_retail_inventory_location?
        product.adjust_sf_inventory
      end
    end
  end

  def adjust_sf_inventory
    begin
      response = ShopifyClient.adjust_inventory(retail_shopify.inventory_item_id, retail_inventory_adjustment)

      if ShopifyClient.inventory_item_updated?(response)
        update_retail_inventory(response)
      else
        puts
        puts
        puts "Could not UPDATE SF inventory for Product: #{id}, Adjustment: #{retail_inventory_adjustment}"
        puts
        Airbrake.notify("Could not UPDATE SF inventory for Product: #{id}, Adjustment: #{retail_inventory_adjustment}")
      end
    rescue
        puts
        puts
        puts "There was an error UPDATING SF inventory for Product: #{id}, Adjustment: #{retail_inventory_adjustment}"
        puts
      Airbrake.notify("There was an error UPDATING SF inventory for Product: #{id}, Adjustment: #{retail_inventory_adjustment}")
    end
  end

  def update_retail_inventory(response)
    InventoryUpdate.create(vend_qty: vend_datum.sf_inventory, prior_qty: shopify_inventory_sf, adjustment: retail_inventory_adjustment, product_id: id, new_qty: response['inventory_level']['available'])
    retail_shopify.update_attribute(:inventory, response['inventory_level']['available'])
  end

  def connect_sf_inventory_location
    begin
      response = ShopifyClient.connect_sf_inventory_location(retail_shopify.inventory_item_id)
      puts
      puts
      puts "Could not CONNECT SF inventory location for Product: #{id}"
      puts
      Airbrake.notify("Could not CONNECT SF inventory location for Product: #{id}") unless ShopifyClient.inventory_item_updated?(response)
    rescue
      puts
      puts
      puts "There was an error CONNECTING SF inventory location for Product: #{id}"
      puts
      Airbrake.notify("There was an error CONNECTING SF inventory for Product: #{id}")
    end
  end

  def retail_shopify
    shopify_data.find_by(store: :retail)
  end

  def shopify_inventory_sf
    retail_shopify.inventory.to_i
  end

  def update_sf_shopify_inventory?
    retail_shopify.third_party_or_sale? && shopify_inventory_sf != vend_datum.sf_inventory && !(vend_datum.sf_inventory < 0 && shopify_inventory_sf.zero?)
  end

  def retail_inventory_adjustment
    vend_datum.sf_inventory - shopify_inventory_sf
  end

  def missing_retail_inventory_location?
    retail_shopify.third_party_or_sale? && retail_shopify.inventory.nil?
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

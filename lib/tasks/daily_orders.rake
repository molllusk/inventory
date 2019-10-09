task daily_orders: :environment do
  daily_order_data = []

  outstanding_orders_by_product = Hash.new { |hash, key| hash[key] = Hash.new(0) }

  release_schedule = Product.get_release_schedule

  release_date_by_handle = {}

  release_schedule.each do |product|
    release_date_by_handle[product['Handle'].to_s.strip.downcase] = Date::strptime(product['Release Date'], "%m/%d/%Y")
  end

  daily_orders = VendClient.daily_orders

  daily_orders.each do |daily_order|
    VendClient.consignment_products(daily_order['id']).each do |product|
      outstanding_orders_by_product[product['product_id']][daily_order['outlet_id']] += product['count'].to_f
    end
  end

  #  Redis.current.set('min_daily_order_version', daily_order.last['version']) if daily_orders.present?

  ShopifyDatum.with_jam.find_each do |shopify_product|
    next if shopify_product.sale?
    vend_product = shopify_product.product.vend_datum
    next unless vend_product.present?
    clean_handle = shopify_product.handle.to_s.strip.downcase
    next if release_date_by_handle[clean_handle].present? && release_date_by_handle[clean_handle] > Date.today

    inventories = {}

    fill_level = shopify_product.product.daily_order_inventory_threshold

    outstanding_orders_by_outlet_id = outstanding_orders_by_product[vend_product.vend_id]

    vend_product.vend_inventories.where(outlet_id: [
          VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'),
          VendClient::OUTLET_NAMES_BY_ID.key('Silver Lake'),
          VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach')
        ]).each do |inventory|

      outstanding_orders = outstanding_orders_by_outlet_id[inventory.outlet_id]
      store_inventory = inventory.inventory < 0 ? 0 : inventory.inventory
      complete_inventory = store_inventory + outstanding_orders
      adjustment = complete_inventory < fill_level ? fill_level - complete_inventory : 0

      if adjustment > 0
        inventories[:fill_level] = fill_level
        inventories[:orders] = outstanding_orders
        case inventory.location
        when 'San Francisco'
          inventories[:sf_vend] = inventory.inventory
          inventories[:sf_adjustment] = adjustment
        when 'Silver Lake'
          inventories[:sl_vend] = inventory.inventory
          inventories[:sl_adjustment] = adjustment
        when 'Venice Beach'
          inventories[:vb_vend] = inventory.inventory
          inventories[:vb_adjustment] = adjustment
        end
      end
    end

    has_adjustment = (inventories[:sf_adjustment].to_i + inventories[:sl_adjustment].to_i + inventories[:vb_adjustment].to_i) > 0

    if has_adjustment
      inventories[:product_id] = shopify_product.product_id

      jam_inventory = shopify_product.shopify_inventories.find_by(location: 'Jam Warehouse Retail')&.inventory.to_i

      if jam_inventory > 0
        inventories[:jam_shopify] = jam_inventory

        adjusted_locations = []
        adjusted_locations << 'Mollusk SF' if inventories[:sf_adjustment].to_i > 0
        adjusted_locations << 'Mollusk SL' if inventories[:sl_adjustment].to_i > 0
        adjusted_locations << 'Mollusk VB' if inventories[:vb_adjustment].to_i > 0

        shopify_product.shopify_inventories.where(location: adjusted_locations).each do |inventory|
          case inventory.location
          when 'Jam Warehouse Retail'
            inventories[:jam_shopify] = inventory.inventory
          when 'Mollusk SF'
            inventories[:sf_shopify] = inventory.inventory
          when 'Mollusk SL'
            inventories[:sl_shopify] = inventory.inventory
          when 'Mollusk VB'
            inventories[:vb_shopify] = inventory.inventory
          end
        end

        daily_order_data << inventories
      end
    end
  end
  p daily_order_data
end

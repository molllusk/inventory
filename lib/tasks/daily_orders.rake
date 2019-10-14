task daily_orders: :environment do
  date = Time.now
  # daily_order_data = []

  daily_inventory_transfer = DailyInventoryTransfer.create(date: date)

  todays_orders = {
    'Mollusk SF' => DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'), daily_inventory_transfer_id: daily_inventory_transfer.id),
    'Mollusk VB' => DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach'), daily_inventory_transfer_id: daily_inventory_transfer.id),
    'Mollusk SL' => DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('Silver Lake'), daily_inventory_transfer_id: daily_inventory_transfer.id)
  }

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
    cost = shopify_product.get_cost

    vend_product.vend_inventories.where(outlet_id: [
          VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'),
          VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach'),
          VendClient::OUTLET_NAMES_BY_ID.key('Silver Lake')
        ]).each do |inventory|

      outstanding_orders = outstanding_orders_by_outlet_id[inventory.outlet_id]
      store_inventory = inventory.inventory < 0 ? 0 : inventory.inventory
      complete_inventory = store_inventory + outstanding_orders
      adjustment = complete_inventory < fill_level ? fill_level - complete_inventory : 0

      if adjustment > 0
        case inventory.location
        when 'San Francisco'
          inventories[:sf_outstanding] = outstanding_orders
          inventories[:sf_vend] = inventory.inventory
          inventories[:sf_adjustment] = adjustment
        when 'Silver Lake'
          inventories[:sl_outstanding] = outstanding_orders
          inventories[:sl_vend] = inventory.inventory
          inventories[:sl_adjustment] = adjustment
        when 'Venice Beach'
          inventories[:vb_outstanding] = outstanding_orders
          inventories[:vb_vend] = inventory.inventory
          inventories[:vb_adjustment] = adjustment
        end
      end
    end

    total_adjustments = inventories[:sf_adjustment].to_i + inventories[:sl_adjustment].to_i + inventories[:vb_adjustment].to_i
    jam_inventory = shopify_product.shopify_inventories.find_by(location: 'Jam Warehouse Retail')&.inventory.to_i
    has_adjustment = total_adjustments > 0 && jam_inventory > 0

    if has_adjustment
      if jam_inventory > 0
        # order is important here: SF -> VB -> SL
        adjusted_locations = []
        adjusted_locations << 'Mollusk SF' if inventories[:sf_adjustment].to_i > 0
        adjusted_locations << 'Mollusk VB' if inventories[:vb_adjustment].to_i > 0
        adjusted_locations << 'Mollusk SL' if inventories[:sl_adjustment].to_i > 0

        adjusted_locations.each do |location|
          break if jam_inventory < 1
          location_order = todays_orders[location]

          case location
          when 'Mollusk SF'
            inventories[:sf_adjustment] = jam_inventory if inventories[:sf_adjustment] > jam_inventory
            location_order.orders.create(quantity: inventories[:sf_adjustment], product_id: shopify_product.product_id, threshold: fill_level, vend_qty: inventories[:sf_vend], cost: cost, sent_orders: inventories[:sf_outstanding])
            jam_inventory -= inventories[:sf_adjustment]
          when 'Mollusk VB'
            inventories[:vb_adjustment] = jam_inventory if inventories[:vb_adjustment] > jam_inventory
            location_order.orders.create(quantity: inventories[:vb_adjustment], product_id: shopify_product.product_id, threshold: fill_level, vend_qty: inventories[:vb_vend], cost: cost, sent_orders: inventories[:vb_outstanding])
            jam_inventory -= inventories[:vb_adjustment]
          when 'Mollusk SL'
            inventories[:sl_adjustment] = jam_inventory if inventories[:sl_adjustment] > jam_inventory
            location_order.orders.create(quantity: inventories[:sl_adjustment], product_id: shopify_product.product_id, threshold: fill_level, vend_qty: inventories[:sl_vend], cost: cost, sent_orders: inventories[:sl_outstanding])
            jam_inventory -= inventories[:sl_adjustment]
          end
        end
      end
      # daily_order_data << inventories
    end
  end

  po_numbers = {
    'Mollusk SF' => (DailyOrder.last_po('San Francisco') || 286) + 1,
    'Mollusk VB' => (DailyOrder.last_po('Venice Beach') || 286) + 1,
    'Mollusk SL' => (DailyOrder.last_po('Silver Lake') || 286) + 1
  }

  todays_orders.each do |location, daily_order|
    if daily_order.orders.count.positive?
      daily_order.update_attribute(po_id: po_numbers[location])
      # daily_order.create_consignment
      # daily_order.send_po
    end
  end

  # daily_inventory_transfer.post_to_qbo
end

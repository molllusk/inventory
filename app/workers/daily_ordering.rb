# frozen_string_literal: true

class DailyOrdering
  include Sidekiq::Worker
  sidekiq_options queue: :orders, retry: false

  def perform
    date = Time.now
    # daily_order_data = []

    next_po_number = DailyInventoryTransfer.last_po + 1

    daily_inventory_transfer = DailyInventoryTransfer.create(date: date)

    sf = DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'))
    vb = DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach'))
    # sb = DailyOrder.create(outlet_id: VendClient::OUTLET_NAMES_BY_ID.key('Santa Barbara'))

    daily_inventory_transfer.daily_orders << sf
    daily_inventory_transfer.daily_orders << vb
    # daily_inventory_transfer.daily_orders << sb

    todays_orders = {
      'Mollusk SF' => sf,
      'Mollusk VB' => vb,
      # 'Mollusk SB' => sb
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
    pacific_time = Time.now.in_time_zone('Pacific Time (US & Canada)').end_of_day

    ShopifyDatum.with_warehouse.find_each do |shopify_product|
      next if shopify_product.sale?
      vend_product = shopify_product.product.vend_datum
      next unless vend_product.present?
      
      clean_handle = shopify_product.handle.to_s.strip.downcase
      product_release_date = release_date_by_handle[clean_handle]
      next if product_release_date.present? && product_release_date > pacific_time

      inventories = {}
      fill_levels = shopify_product.product.daily_order_inventory_thresholds

      days_since_release = product_release_date.present? ? (pacific_time.to_date - product_release_date).to_i : 420
      new_release = days_since_release < 30 && fill_levels['new_release_fill'].present?

      fill_level = (new_release ? fill_levels['new_release_fill'] : fill_levels['fill']).to_i

      outstanding_orders_by_outlet_id = outstanding_orders_by_product[vend_product.vend_id]

      cost = shopify_product.get_cost

      vend_product.vend_inventories.where(outlet_id: [
            VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'),
            VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach'),
            # VendClient::OUTLET_NAMES_BY_ID.key('Santa Barbara')
          ]).each do |inventory|

        outstanding_orders = outstanding_orders_by_outlet_id[inventory.outlet_id]
        store_inventory = inventory.inventory < 0 ? 0 : inventory.inventory
        complete_inventory = store_inventory + outstanding_orders

        # fill_level = fill_levels['fill'].to_i if new_release && inventory.location == 'Santa Barbara'
        adjustment = complete_inventory < fill_level ? fill_level - complete_inventory : 0

        if adjustment > 0
          case inventory.location
          when 'San Francisco'
            inventories[:sf_outstanding] = outstanding_orders
            inventories[:sf_vend] = inventory.inventory
            inventories[:sf_adjustment] = adjustment
          # when 'Santa Barbara'
          #   inventories[:sb_outstanding] = outstanding_orders
          #   inventories[:sb_vend] = inventory.inventory
          #   inventories[:sb_adjustment] = adjustment
          when 'Venice Beach'
            inventories[:vb_outstanding] = outstanding_orders
            inventories[:vb_vend] = inventory.inventory
            inventories[:vb_adjustment] = adjustment
          end
        end
      end

      total_adjustments = inventories[:sf_adjustment].to_i + inventories[:vb_adjustment].to_i #+ inventories[:sb_adjustment].to_i 
      warehouse_inventory = shopify_product.shopify_inventories.find_by(location: 'Postworks')&.inventory.to_i
      has_adjustment = total_adjustments > 0 && warehouse_inventory > 0

      if has_adjustment
        if warehouse_inventory > 0
          # order is important here: SF -> VB -> SB
          adjusted_locations = []
          adjusted_locations << 'Mollusk SF' if inventories[:sf_adjustment].to_i > 0
          adjusted_locations << 'Mollusk VB' if inventories[:vb_adjustment].to_i > 0
          # adjusted_locations << 'Mollusk SB' if inventories[:sb_adjustment].to_i > 0

          adjusted_locations.each do |location|
            break if warehouse_inventory < 1
            location_order = todays_orders[location]

            case location
            when 'Mollusk SF'
              inventories[:sf_adjustment] = warehouse_inventory if inventories[:sf_adjustment] > warehouse_inventory
              location_order.orders.create(
                  quantity: inventories[:sf_adjustment],
                  product_id: shopify_product.product_id,
                  threshold: fill_level,
                  vend_qty: inventories[:sf_vend],
                  cost: cost,
                  sent_orders: inventories[:sf_outstanding]
                )
              warehouse_inventory -= inventories[:sf_adjustment]
            when 'Mollusk VB'
              inventories[:vb_adjustment] = warehouse_inventory if inventories[:vb_adjustment] > warehouse_inventory
              location_order.orders.create(
                  quantity: inventories[:vb_adjustment],
                  product_id: shopify_product.product_id,
                  threshold: fill_level,
                  vend_qty: inventories[:vb_vend],
                  cost: cost,
                  sent_orders: inventories[:vb_outstanding]
                )
              warehouse_inventory -= inventories[:vb_adjustment]
            # when 'Mollusk SB'
            #   inventories[:sb_adjustment] = warehouse_inventory if inventories[:sb_adjustment] > warehouse_inventory
            #   location_order.orders.create(
            #       quantity: inventories[:sb_adjustment],
            #       product_id: shopify_product.product_id,
            #       threshold: fill_level,
            #       vend_qty: inventories[:sb_vend],
            #       cost: cost,
            #       sent_orders: inventories[:sb_outstanding]
            #     )
            #   warehouse_inventory -= inventories[:sb_adjustment]
            end
          end
        end
        # daily_order_data << inventories
      end
    end

    todays_orders.each do |location, daily_order|
      if daily_order.orders.count.positive?
        daily_inventory_transfer.update_attributes(po_id: next_po_number) unless daily_order.has_po?
        daily_order.create_consignment
      end
    end

    if daily_inventory_transfer.has_orders?
      daily_inventory_transfer.fluid_inventory
      daily_inventory_transfer.post_to_qbo
      daily_inventory_transfer.send_po
    end
  end
end

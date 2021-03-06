# frozen_string_literal: true

class DailyOrdering
  include Sidekiq::Worker
  sidekiq_options queue: :orders, retry: false

  def perform
    date = Time.now

    next_po_number = DailyInventoryTransfer.last_po + 1

    daily_inventory_transfer = DailyInventoryTransfer.create(date: date)

    sf = DailyOrder.create(outlet_id: ShopifyClient::OUTLET_NAMES_BY_ID.key('San Francisco'))
    vb = DailyOrder.create(outlet_id: ShopifyClient::OUTLET_NAMES_BY_ID.key('Venice Beach'))
    sb = DailyOrder.create(outlet_id: ShopifyClient::OUTLET_NAMES_BY_ID.key('Santa Barbara'))

    daily_inventory_transfer.daily_orders << sf
    daily_inventory_transfer.daily_orders << vb
    daily_inventory_transfer.daily_orders << sb

    todays_orders = {
      'Mollusk SF' => sf,
      'Mollusk VB' => vb,
      'Mollusk SB' => sb
    }

    outstanding_orders_by_variant = Hash.new { |hash, key| hash[key] = Hash.new(0) }

    daily_orders_ip = InventoryPlannerClient.open_store_purchase_orders['purchase-orders']

    if daily_orders_ip.present?
      daily_orders_ip.each do |daily_order|
        ip_shop = daily_order['warehouse']
        next unless InventoryPlannerClient::IP_SHOPS.include?(ip_shop)

        daily_order['items'].each do |item|
          variant_id = ShopifyDatum.find_by(barcode: item['barcode'])&.variant_id
          outstanding_orders_by_variant[variant_id][InventoryPlannerClient.shopify_location(ip_shop)] += item['replenishment'].to_f if variant_id.present?
        end
      end
    end

    draft_orders = ShopifyClient.all_draft_orders('invoice_sent')

    draft_orders_by_variant = Hash.new(0)

    draft_orders.each do |order|
      order['line_items'].each do |line_item|
        next unless line_item['variant_id'].present? # some line items are empty?

        draft_orders_by_variant[line_item['variant_id']] += line_item['quantity']
      end
    end

    #  Redis.current.set('min_daily_order_version', daily_order.last['version']) if daily_orders.present?

    ShopifyDatum.with_warehouse.find_each do |shopify_product|
      next if shopify_product.sale?

      inventories = {}
      fill_levels = shopify_product.product.daily_order_inventory_thresholds

      outstanding_orders_by_location = outstanding_orders_by_variant[shopify_product.variant_id]
      outstanding_draft_orders = draft_orders_by_variant[shopify_product.variant_id]

      cost = shopify_product.get_cost

      shopify_product.shopify_inventories.where(location: shopify_product.order_locations(todays_orders.keys)).each do |inventory|
        outstanding_orders = outstanding_orders_by_location[inventory.location]

        fill_level = fill_levels[inventory.city].to_i

        store_inventory = inventory.inventory.negative? ? 0 : inventory.inventory

        complete_inventory = store_inventory + outstanding_orders

        adjustment = complete_inventory < fill_level ? fill_level - complete_inventory : 0

        next unless adjustment.positive?

        case inventory.location
        when 'San Francisco', 'Mollusk SF'
          inventories[:sf_outstanding] = outstanding_orders
          inventories[:sf_shopify] = inventory.inventory
          inventories[:sf_adjustment] = adjustment
        when 'Santa Barbara', 'Mollusk SB'
          inventories[:sb_outstanding] = outstanding_orders
          inventories[:sb_shopify] = inventory.inventory
          inventories[:sb_adjustment] = adjustment
        when 'Venice Beach', 'Mollusk VB'
          inventories[:vb_outstanding] = outstanding_orders
          inventories[:vb_shopify] = inventory.inventory
          inventories[:vb_adjustment] = adjustment
        end
      end

      # Minimum we want to keep in Shopify so that we don't over order.
      minimum_reserve = 2
      total_adjustments = inventories[:sf_adjustment].to_i + inventories[:vb_adjustment].to_i + inventories[:sb_adjustment].to_i
      warehouse_inventory = shopify_product.shopify_inventories.find_by(location: 'Shopify Fulfillment Network')&.inventory.to_i - outstanding_draft_orders - minimum_reserve
      has_adjustment = total_adjustments.positive? && warehouse_inventory.positive?

      if has_adjustment && warehouse_inventory.positive?
        # order is important here: SF -> VB -> SB
        adjusted_locations = []
        adjusted_locations << 'Mollusk SF' if inventories[:sf_adjustment].to_i.positive?
        adjusted_locations << 'Mollusk VB' if inventories[:vb_adjustment].to_i.positive?
        adjusted_locations << 'Mollusk SB' if inventories[:sb_adjustment].to_i.positive?

        adjusted_locations.each do |location|
          break if warehouse_inventory < 1

          location_order = todays_orders[location]

          case location
          when 'Mollusk SF'
            inventories[:sf_adjustment] = warehouse_inventory if inventories[:sf_adjustment] > warehouse_inventory
            location_order.orders.create(
              quantity: inventories[:sf_adjustment],
              product_id: shopify_product.product_id,
              threshold: fill_levels['San Francisco'].to_i,
              vend_qty: inventories[:sf_shopify],
              cost: cost,
              sent_orders: inventories[:sf_outstanding]
            )
            warehouse_inventory -= inventories[:sf_adjustment]
          when 'Mollusk VB'
            inventories[:vb_adjustment] = warehouse_inventory if inventories[:vb_adjustment] > warehouse_inventory
            location_order.orders.create(
              quantity: inventories[:vb_adjustment],
              product_id: shopify_product.product_id,
              threshold: fill_levels['Venice Beach'].to_i,
              vend_qty: inventories[:vb_shopify],
              cost: cost,
              sent_orders: inventories[:vb_outstanding]
            )
            warehouse_inventory -= inventories[:vb_adjustment]
          when 'Mollusk SB'
            inventories[:sb_adjustment] = warehouse_inventory if inventories[:sb_adjustment] > warehouse_inventory
            location_order.orders.create(
              quantity: inventories[:sb_adjustment],
              product_id: shopify_product.product_id,
              threshold: fill_levels['Santa Barbara'].to_i,
              vend_qty: inventories[:sb_shopify],
              cost: cost,
              sent_orders: inventories[:sb_outstanding]
            )
            warehouse_inventory -= inventories[:sb_adjustment]
          end
        end
      end
    end

    return unless daily_inventory_transfer.orders?

    daily_inventory_transfer.update_attributes(po_id: next_po_number)
    daily_inventory_transfer.post_to_inventory_planner
    daily_inventory_transfer.post_to_qbo
    daily_inventory_transfer.post_to_shopify
    daily_inventory_transfer.send_po
  end
end

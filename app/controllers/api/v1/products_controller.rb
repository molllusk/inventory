module Api
  class V1::ProductsController < Api::Controller
    def shopify_jammers
      inventories = ShopifyInventory.where('location = ? AND inventory > 0', ShopifyInventory::locations['Jam Warehouse Retail'])
      products = []

      ShopifyDatum.retail.joins(:shopify_inventories).merge(inventories).find_each do |product|
        product_data = {
          name: product.full_title,
          sku: product.barcode,
          type: product.product_type
        }

        product.shopify_inventories.where(location: [
              ShopifyInventory::locations['Jam Warehouse Retail'],
              ShopifyInventory::locations['Mollusk SF'],
              ShopifyInventory::locations['Mollusk SL'],
              ShopifyInventory::locations['Mollusk VB']
            ]).each do |inventory|
          case inventory.location
          when 'Jam Warehouse Retail'
            product_data[:jam_inv] = inventory.inventory
          when 'Mollusk SF'
            product_data[:sf_inv] = inventory.inventory
          when 'Mollusk SL'
            product_data[:sl_inv] = inventory.inventory
          when 'Mollusk VB'
            product_data[:vb_inv] = inventory.inventory
          end
        end
        products << product_data
      end

      render json: { jammers: products.as_json }
    end

    def vend_inventories
      products = []

      VendDatum.find_each do |product|
        product_data = {
          name: product.variant_name,
          sku: product.sku,
          product_type: product.vend_type&.[]('name')
        }

        product.vend_inventories.where(outlet_id: [
              VendClient::OUTLET_NAMES_BY_ID.key['San Francisco'],
              VendClient::OUTLET_NAMES_BY_ID.key['Silver Lake'],
              VendClient::OUTLET_NAMES_BY_ID.key['Venice Beach']
            ]).each do |inventory|
          case inventory.location
          when 'San Francisco'
            product_data[:sf_inv] = inventory.inventory
          when 'Silver Lake'
            product_data[:sl_inv] = inventory.inventory
          when 'Venice Beach'
            product_data[:vb_inv] = inventory.inventory
          end
        end
        products << product_data
      end

      render json: { vend_inventories: products.as_json }
    end
  end
end

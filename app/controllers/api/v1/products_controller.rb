module Api
  class V1::ProductsController < Api::Controller
    def shopify_jammers
      products = []

      ShopifyDatum.with_jam.find_each do |product|
        next if product.sale?

        product_data = {
          variant_id: product.variant_id,
          name: product.full_title,
          size: product.option1,
          barcode: product.barcode,
          sku: product.sku,
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

      render json: { shopify_jammers: products.as_json }
    end

    def vend_jammers
      products = []

      VendDatum.where(product_id: ShopifyDatum.with_jam.pluck(:product_id)).find_each do |product|
        next if ShopifyDatum.find_by(product_id: product.product_id)&.sale?

        size = product.variant_options.find { |vo| vo['name'] == 'Size' }&.[]('value')

        product_data = {
          id: product.vend_id,
          name: product.variant_name,
          size: size,
          sku: product.sku,
          supply_price: product.supply_price.to_f,
          type: product.vend_type&.[]('name')
        }

        product.vend_inventories.where(outlet_id: [
              VendClient::OUTLET_NAMES_BY_ID.key('San Francisco'),
              VendClient::OUTLET_NAMES_BY_ID.key('Silver Lake'),
              VendClient::OUTLET_NAMES_BY_ID.key('Venice Beach')
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

      render json: { vend_jammers: products.as_json }
    end
  end
end

module Api
  class V1::ProductsController < Api::Controller
    def jammers
      inventories = ShopifyInventory.where('location = ? AND inventory > 0', ShopifyInventory::locations['Jam Warehouse Retail'])
      products = []

      ShopifyDatum.joins(:shopify_inventories).merge(inventories).find_each do |product|
        product_data = {
          name: product.full_title,
          sku: product.barcode
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
  end
end

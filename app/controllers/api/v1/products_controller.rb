class Api::V1::ProductsController < ApplicationController

  def jammers
    inventories = ShopifyInventory.where('location = ? AND inventory > 0', ShopifyInventory::locations['Jam Warehouse Retail'])
    products = []

    ShopifyDatum.joins(:shopify_inventories).merge(inventories).find_each do |product|
      products << {
        name: product.full_title,
        sku: product.barcode,
        jam_inv: product.shopify_inventories.find_by(location: ShopifyInventory::locations['Jam Warehouse Retail'])&.inventory,
        sf_inv:product.shopify_inventories.find_by(location: ShopifyInventory::locations['Mollusk SF'])&.inventory,
        sl_inv:product.shopify_inventories.find_by(location: ShopifyInventory::locations['Mollusk SL'])&.inventory,
        vb_inv:product.shopify_inventories.find_by(location: ShopifyInventory::locations['Mollusk VB'])&.inventory
      }
    end

    render json: products.as_json
  end
end

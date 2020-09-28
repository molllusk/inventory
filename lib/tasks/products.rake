# frozen_string_literal: true

namespace :products do
  task pull: :environment do
    shopify_products = ShopifyClient.all_products
    vend_products = VendClient.active_products

    new_vends = []
    new_shopifys = []

    vend_products.each do |vend_product|
      vend_attrs = VendClient.product_attributes(vend_product)
      vend_datum = VendDatum.find_by(vend_id: vend_attrs[:vend_id])

      if vend_datum.present?
        # https://stackoverflow.com/questions/21297506/update-attributes-for-user-only-if-attributes-have-changed
        vend_datum.attributes = vend_attrs
        vend_datum.save if vend_datum.changed?
      else
        new_vends << vend_attrs
      end
    end

    shopify_products.each do |shopify_product|
      shopify_attrs_list = ShopifyClient.products_attributes(shopify_product)
      shopify_attrs_list.each do |shopify_attrs|
        shopify_datum = ShopifyDatum.find_by(variant_id: shopify_attrs[:variant_id])
        if shopify_datum.present?
          # https://stackoverflow.com/questions/21297506/update-attributes-for-user-only-if-attributes-have-changed
          shopify_datum.attributes = shopify_attrs
          shopify_datum.save if shopify_datum.changed?
        else
          new_shopifys << shopify_attrs
        end
      end
    end

    # match vend variant sku to shopify variant barcode
    new_shopifys.each do |shopify_attrs|
      shopify_attrs[:store] = :retail
      existing_vend = VendDatum.find_by(sku: shopify_attrs[:barcode])
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:barcode] }
      existing_shopify = existing_vend.product.retail_shopify

      if existing_vend.present? && existing_shopify.present?
        # Get the shopify product from shopify.
        existing_shopify_variant_id = existing_shopify.variant_id
        shopify_variant = ShopifyClient.get_variant()

        if shopify_variant.blank?
          # delete
          if (existing_shopify.destroy)
            existing_vend.product << ShopifyDeletion.new(deleted_variant_id: existing_shopify_variant_id, new_variant_id: shopify_attrs[:variant_id])
          end
        else
          # duplicate
          existing_duplicate = existing_vend.product.duplicate.where(original_variant_id: existing_shopify_variant_id, duplicate_variant_id: shopify_attrs[:variant_id])
          if (existing_duplicate)
            existing_duplicate.touch
          else
            existing_vend.product << ShopifyDuplicate.new(original_variant_id: existing_shopify_variant_id, duplicate_variant_id: shopify_attrs[:variant_id])
          end
        end
        Airbrake.notify("Issue Importing Shopify Product: recognized as new, but already exists for product: #{existing_vend.product.id}")
      elsif existing_vend.present?
        existing_vend.product.shopify_data << ShopifyDatum.create(shopify_attrs)
      elsif vend_attrs.present?
        new_vend = VendDatum.create(vend_attrs)
        new_vend.product = Product.create
        new_vend.product.shopify_data << ShopifyDatum.create(shopify_attrs)
        new_vend.save
      end
    end
  end
end

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

      if existing_vend.present? && existing_vend.product.shopify_datum.present?
        # This is either a duplicate or a replacement product
        product = existing_vend.product
        existing_shopify = product.shopify_datum
        existing_shopify_variant_id = existing_shopify.variant_id
        existing_shopify_product_id = existing_shopify.shopify_product_id
        shopify_variant = ShopifyClient.get_variant(existing_shopify_variant_id)

        if shopify_variant.blank? # delete and replace
          if existing_shopify.destroy
            product.shopify_deletions << ShopifyDeletion.create(
              deleted_variant_id: existing_shopify_variant_id,
              new_variant_id: shopify_attrs[:variant_id],
              deleted_shopify_product_id: existing_shopify_product_id,
              new_shopify_product_id: shopify_attrs[:shopify_product_id]
            )

            product.shopify_data << ShopifyDatum.create(shopify_attrs)
          end
        else # duplicate
          existing_shopify_duplicate = product.shopify_duplicates.find_by(original_variant_id: existing_shopify_variant_id, duplicate_variant_id: shopify_attrs[:variant_id])
          
          if existing_shopify_duplicate.present?
            existing_shopify_duplicate.touch
          else
            product.shopify_duplicates << ShopifyDuplicate.create(
              original_variant_id: existing_shopify_variant_id,
              duplicate_variant_id: shopify_attrs[:variant_id],
              original_shopify_product_id: existing_shopify_product_id,
              duplicate_shopify_product_id: shopify_attrs[:shopify_product_id]
            )
          end
        end
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

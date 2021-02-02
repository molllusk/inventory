# frozen_string_literal: true

namespace :products do
  task pull: :environment do
    shopify_products = ShopifyClient.all_products
    vend_products = VendClient.active_products

    new_vends = []
    new_shopifys = []

    newly_created_shopifys = []

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
      existing_vend = VendDatum.find_by(sku: shopify_attrs[:barcode])
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:barcode] }

      if existing_vend.present? && existing_vend.product.shopify_datum.present?
        # Get the shopify product from shopify.
        product = existing_vend.product
        existing_shopify = product.shopify_datum
        existing_shopify_variant_id = existing_shopify.variant_id
        existing_shopify_product_id = existing_shopify.shopify_product_id

        # when a shopify product with a duplicate sku shows up check to see if the original still exists in shopify
        # if not, delete and replace it in the app
        shopify_variant = ShopifyClient.get_variant(existing_shopify_variant_id)

        if shopify_variant.blank? # delete
          if existing_shopify.destroy
            product.shopify_deletions << ShopifyDeletion.create(
              deleted_variant_id: existing_shopify_variant_id,
              new_variant_id: shopify_attrs[:variant_id],
              deleted_shopify_product_id: existing_shopify_product_id,
              new_shopify_product_id: shopify_attrs[:shopify_product_id]
            )

            newly_created_shopifys << product.create_shopify_datum(shopify_attrs)
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
        newly_created_shopifys << existing_vend.product.create_shopify_datum(shopify_attrs)
      elsif vend_attrs.present?
        product = Product.create
        product.create_vend_datum(vend_attrs)
        newly_created_shopifys << product.create_shopify_datum(shopify_attrs)
      end
    end

    Product.update_shopify_costs(newly_created_shopifys.map(&:inventory_item_id)) if newly_created_shopifys.present?
  end
end

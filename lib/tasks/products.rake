# frozen_string_literal: true

namespace :products do
  task pull: :environment do
    shopify_products = ShopifyClient.all_products

    new_shopifys = []
    newly_created_shopifys = []

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

    new_shopifys.each do |shopify_attrs|
      if ShopifyDatum.where(barcode: shopify_attrs[:barcode]).exists?
        existing_shopify = ShopifyDatum.find_by(barcode: shopify_attrs[:barcode])
        product = existing_shopify.product
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
      elsif VendDatum.where(sku: shopify_attrs[:barcode]).exists?
        existing_vend = VendDatum.find_by(sku: shopify_attrs[:barcode])
        newly_created_shopifys << existing_vend.product.create_shopify_datum(shopify_attrs)
      else
        product = Product.create
        newly_created_shopifys << product.create_shopify_datum(shopify_attrs)
      end
    end

    Product.update_shopify_costs(newly_created_shopifys.map(&:inventory_item_id)) if newly_created_shopifys.present?
  end
end

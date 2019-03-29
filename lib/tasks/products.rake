namespace :products do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    retail_shopify_products = ShopifyClient.all_products
    wholesale_shopify_products = ShopifyClient.all_products(:wholesale)
    vend_products = VendClient.active_products

    new_vends = []
    new_retail_shopifys = []
    new_wholesale_shopifys = []

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

    retail_shopify_products.each do |shopify_product|
      shopify_attrs_list = ShopifyClient.products_attributes(shopify_product)
      shopify_attrs_list.each do |shopify_attrs|
        shopify_datum = ShopifyDatum.find_by(variant_id: shopify_attrs[:variant_id])
        if shopify_datum.present?
          # https://stackoverflow.com/questions/21297506/update-attributes-for-user-only-if-attributes-have-changed
          shopify_datum.attributes = shopify_attrs
          shopify_datum.save if shopify_datum.changed?
        else
          new_retail_shopifys << shopify_attrs
        end
      end
    end

    wholesale_shopify_products.each do |shopify_product|
      shopify_attrs_list = ShopifyClient.products_attributes(shopify_product)
      shopify_attrs_list.each do |shopify_attrs|
        shopify_datum = ShopifyDatum.find_by(variant_id: shopify_attrs[:variant_id])
        if shopify_datum.present?
          # https://stackoverflow.com/questions/21297506/update-attributes-for-user-only-if-attributes-have-changed
          shopify_datum.attributes = shopify_attrs
          shopify_datum.save if shopify_datum.changed?
        else
          new_wholesale_shopifys << shopify_attrs
        end
      end
    end

    # match vend variant sku to shopify variant barcode
    new_retail_shopifys.each do |shopify_attrs|
      shopify_attrs[:store] = :retail
      existing_vend = VendDatum.find_by(sku: shopify_attrs[:barcode])
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:barcode] }

      if existing_vend.present? && existing_vend.product.retail_shopify.present?
        Airbrake.notify("Issue Importing RETAIL Shopify: recognized as new, but already exists for product: #{existing_vend.product.id}")
      else
        if existing_vend.present?
          existing_vend.product.shopify_data << ShopifyDatum.create(shopify_attrs)
        elsif vend_attrs.present?
          new_vend = VendDatum.create(vend_attrs)
          new_vend.product = Product.create
          new_vend.product.shopify_data << ShopifyDatum.create(shopify_attrs)
          new_vend.save
        end
      end
    end

    new_wholesale_shopifys.each do |shopify_attrs|
      shopify_attrs[:store] = :wholesale
      existing_vend = VendDatum.find_by(sku: shopify_attrs[:barcode])
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:barcode] }

      if existing_vend.present? && existing_vend.product.wholesale_shopify.present?
        Airbrake.notify("Issue Importing WHOLESALE Shopify: recognized as new, but already exists for product: #{existing_vend.product.id}")
      else
        if existing_vend.present?
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
end

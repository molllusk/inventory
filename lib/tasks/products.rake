namespace :products do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    shopify_products = ShopifyClient.all_products
    vend_products = VendClient.active_products

    new_vends = []
    new_shopifys = []

    vend_products.each do |vend_product|
      vend_attrs = VendClient.product_attributes(vend_product)
      vend_datum = VendDatum.find_by_sku(vend_attrs[:sku])

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
        shopify_datum = ShopifyDatum.find_by_barcode(shopify_attrs[:barcode])
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
      existing_vend = VendDatum.find_by_sku(shopify_attrs[:barcode])
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:barcode] }

      if existing_vend.present? && existing_vend.product.shopify_datum.present?
        Airbrake.notify("Issue Importing Shopify: recognized as new, but already exists for product: #{existing_vend.product.id}")
      else
        if existing_vend.present?
          existing_vend.product.create_shopify_datum(shopify_attrs)
        elsif vend_attrs.present?
          new_vend = VendDatum.create(vend_attrs)
          new_vend.product = Product.create
          new_vend.product.create_shopify_datum(shopify_attrs)
          new_vend.save
        end
      end
    end
  end
end

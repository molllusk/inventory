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
        shopify_datum = ShopifyDatum.find_by_sku(shopify_attrs[:sku])
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
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:sku] }

      if vend_attrs.present?
        product = VendDatum.create_product(vend_attrs).try(:product)
        product.create_shopify_datum(shopify_attrs) if product.present?
      end
    end
  end
end

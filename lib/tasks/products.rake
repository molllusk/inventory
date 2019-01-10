namespace :products do
  task pull: :environment do
    require File.join(Rails.root, 'app', 'lib', 'vend.rb')
    require File.join(Rails.root, 'app', 'lib', 'shopify.rb')

    shopify_products = ShopifyClient.all_products;nil
    vend_products = VendClient.active_products;nil

    new_vends = []
    new_shopifys = []

    vend_products.each do |vend_product|
      vend_attrs = VendClient.product_attributes(vend_product)
      vend_datum = VendDatum.find_by_vend_id(vend_attrs[:vend_id])

      if vend_datum.present?
        vend_datum.update_if_changed(vend_attrs)
      else
        new_vends << vend_attrs
      end
    end

    shopify_products.each do |shopify_product|
      shopify_attrs_list = ShopifyClient.products_attributes(shopify_product)
      shopify_attrs_list.each do |shopify_attrs|
        shopify_datum = ShopifyDatum.find_by_shopify_product_id(shopify_attrs[:shopify_product_id])

        if shopify_datum.present?
          shopify_datum.update_if_changed(shopify_attrs)
        else
          new_shopifys << shopify_attrs
        end
      end
    end
    # Product.update_inventories

    new_shopifys.each do |shopify_attrs|
      vend_attrs = new_vends.find { |vend| vend[:sku] == shopify_attrs[:sku] }

      if vend_attrs.present?
        product = VendDatum.create_product(vend_attrs).try(:product)
        product.create_shopify_datum(shopify_attrs) if product.present?
      end
    end
  end
end

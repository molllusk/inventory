# frozen_string_literal: true

class SkuCheck
  include Sidekiq::Worker

  def perform
    bad_retail_products = []
    bad_wholesale_products = []

    Product.find_each do |product|
      vend_sku = product.vend_datum.sku

      if product.retail_shopify.present?
        bad_retail_products << product unless product.retail_shopify.barcode == vend_sku
      end

      if product.wholesale_shopify.present?
        bad_wholesale_products << product unless product.wholesale_shopify.barcode == vend_sku
      end
    end

    ApplicationMailer.sku_report(bad_retail_products, bad_wholesale_products).deliver unless (bad_retail_products + bad_wholesale_products).blank?
  end
end

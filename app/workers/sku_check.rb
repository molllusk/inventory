# frozen_string_literal: true

class SkuCheck
  include Sidekiq::Worker

  def perform
    bad_products = []

    Product.find_each do |product|
      vend_sku = product.vend_datum.sku

      if product.shopify_datum.present?
        bad_products << product unless product.shopify_datum.barcode == vend_sku
      end
    end

    ApplicationMailer.sku_report(bad_products).deliver unless bad_products.blank?
  end
end

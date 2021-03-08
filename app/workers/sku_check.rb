# frozen_string_literal: true

class SkuCheck
  include Sidekiq::Worker

  def perform
    bad_products = []

    Product.find_each do |product|
      vend_sku = product.vend_datum&.sku
      next if vend_sku.blank?

      bad_products << product if product.shopify_datum.present? && product.shopify_datum.barcode != vend_sku
    end

    ApplicationMailer.sku_report(bad_products).deliver unless bad_products.blank?
  end
end

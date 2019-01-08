class Product < ApplicationRecord
  has_one :vend_datum, dependent: :destroy
  has_one :shopify_datum, dependent: :destroy

  CSV_HEADERS = %w(id name vend shopify difference url)

  def self.inventory_check
    csv = inventory_check_csv
    ApplicationMailer.inventory_check(csv).deliver if CSV.parse(csv).count > 1
  end

  def self.inventory_check_csv
    CSV.generate(headers: CSV_HEADERS, write_headers: true) do |csv|
      find_each do |product|
        vend_inventory = product.vend_datum.inventory.to_i
        shopify_inventory = product.shopify_datum.inventory.to_i
        csv << [
          product.id,
          "#{product.vend_datum.name} #{product.vend_datum.variant_name}".strip,
          vend_inventory,
          shopify_inventory,
          vend_inventory - shopify_inventory,
          "https://mollusk.herokuapp.com/products/#{product.id}"
        ] if vend_inventory != shopify_inventory
      end
    end
  end

  def has_shopify?
    shopify_datum.present?
  end
end

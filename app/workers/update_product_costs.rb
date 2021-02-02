# frozen_string_literal: true

class UpdateProductCosts
  include Sidekiq::Worker
  sidekiq_options queue: :orders

  def perform
    Product.update_shopify_costs
  end
end

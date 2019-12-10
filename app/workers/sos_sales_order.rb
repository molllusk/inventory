# frozen_string_literal: true

class SosSalesOrder
  include Sidekiq::Worker
  sidekiq_options queue: :orders, retry: false

  def perform
    WholesaleOrder.create_orders
  end
end

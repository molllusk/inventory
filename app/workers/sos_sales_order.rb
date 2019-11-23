# frozen_string_literal: true

class SosSalesOrder
  include Sidekiq::Worker
  sidekiq_options max_retries: 0

  def perform
    WholesaleOrder.create_orders
  end
end

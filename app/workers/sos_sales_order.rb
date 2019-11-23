# frozen_string_literal: true

class SosSalesOrder
  include Sidekiq::Worker

  def perform
    WholesaleOrder.create_orders
  end
end

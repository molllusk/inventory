class WholesaleOrdersController < ApplicationController
  def index
    @wholesale_orders = [] # WholesaleOrder.all
  end

  def post_to_sos
    # p WholesaleOrder.process_orders
    render :plain => WholesaleOrder.process_orders.to_json, status: 200, content_type: 'application/json'
  end
end

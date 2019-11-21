class WholesaleOrdersController < ApplicationController
  def index
    @wholesale_orders = [] # WholesaleOrder.all
  end
end

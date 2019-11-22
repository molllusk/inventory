class WholesaleOrdersController < ApplicationController
  before_action :logged_in_user

  def index
    @wholesale_orders = WholesaleOrder.all.paginate(page: params[:page], per_page: 20)
  end

  def show
    @wholesale_order = WholesaleOrder.find(params[:id])
  end

  def post_to_sos
    WholesaleOrder.create_orders
    redirect_to action: :index
  end
end

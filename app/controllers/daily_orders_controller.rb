class DailyOrdersController < ApplicationController
  before_action :logged_in_user

  def index
    @daily_orders = DailyOrder.order('date DESC').paginate(page: params[:page], per_page: 60).group_by { |order| order.date }
  end

  def show
    @daily_order = DailyOrder.find(params[:id])
  end
end

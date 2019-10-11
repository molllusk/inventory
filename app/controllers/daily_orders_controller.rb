class DailyOrdersController < ApplicationController
  before_action :logged_in_user

  def index
    @daily_orders = DailyOrder.all.group_by { |order| order.date }
  end
end

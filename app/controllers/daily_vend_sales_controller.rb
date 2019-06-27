class DailyVendSalesController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_sale = DailyVendSale.find(params[:id])
  end
end

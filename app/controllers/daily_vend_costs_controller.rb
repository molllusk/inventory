class DailyVendCostsController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_costs = DailyVendCosts.find(params[:id])
  end
end

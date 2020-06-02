# frozen_string_literal: true

class DailyVendCostsController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_costs = DailyVendCost.find(params[:id])
  end
end

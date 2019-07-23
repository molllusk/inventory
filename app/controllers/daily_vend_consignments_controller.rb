class DailyVendConsignmentsController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_vend_consignment = DailyVendConsignment.find(params[:id])
  end
end

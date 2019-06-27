class VendSalesCostsController < ApplicationController
  before_action :logged_in_user

  def show
    @vend_sales_cost = VendSalesCost.find(params[:id])
  end
end

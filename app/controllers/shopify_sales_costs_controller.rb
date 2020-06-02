# frozen_string_literal: true

class ShopifySalesCostsController < ApplicationController
  before_action :logged_in_user

  def show
    @shopify_sales_cost = ShopifySalesCost.find(params[:id])
  end
end

# frozen_string_literal: true

class DailyShopifyPosCostsController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_shopify_pos_costs = DailyShopifyPosCost.find(params[:id])
  end
end

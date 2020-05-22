# frozen_string_literal: true

class ShopifyRefundsController < ApplicationController
  before_action :logged_in_user

  def show
    @shopify_refund = ShopifyRefund.find(params[:id])
  end
end

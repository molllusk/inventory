class ShopifySalesReceiptsController < ApplicationController
  before_action :logged_in_user

  def show
    @shopify_sales_receipt = ShopifySalesReceipt.find(params[:id])
  end
end

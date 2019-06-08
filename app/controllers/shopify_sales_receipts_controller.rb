class ShopifySalesReceiptsController < ApplicationController
  before_action :logged_in_user

  def index
    @filterrific = initialize_filterrific(
      ShopifySalesReceipt,
      params[:filterrific]
    ) or return

    @shopify_sales_receipts = @filterrific.find.page(params[:page])
  end
end

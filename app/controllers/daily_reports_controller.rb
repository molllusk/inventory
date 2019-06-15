class DailyReportsController < ApplicationController
  before_action :logged_in_user

  def index
    @shopify_sales_receipts = ShopifySalesReceipt.order('date DESC').paginate(page: params[:page], per_page: 10)
    @shopify_costs = ShopifySalesCost.order('date DESC').paginate(page: params[:page], per_page: 10)
    @shopify_refunds = ShopifyRefund.order('date DESC').paginate(page: params[:page], per_page: 10)
  end
end

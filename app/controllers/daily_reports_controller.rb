class DailyReportsController < ApplicationController
  before_action :logged_in_user

  def index
    @shopify_sales_receipts = ShopifySalesReceipt.retail.order('date DESC').paginate(page: params[:page], per_page: 10)
    @shopify_costs = ShopifySalesCost.retail.order('date DESC').paginate(page: params[:page], per_page: 10)
    @wholesale_shopify_sales_receipts = ShopifySalesReceipt.wholesale.order('date DESC').paginate(page: params[:page], per_page: 10)
    @wholesale_shopify_costs = ShopifySalesCost.wholesale.order('date DESC').paginate(page: params[:page], per_page: 10)
    @shopify_refunds = ShopifyRefund.order('date DESC').paginate(page: params[:page], per_page: 10)
    @vend_costs = DailyVendCost.order('date DESC').paginate(page: params[:page], per_page: 10)
    @vend_sales = DailyVendSale.order('date DESC').paginate(page: params[:page], per_page: 10)
  end
end

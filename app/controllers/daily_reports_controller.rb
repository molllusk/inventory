class DailyReportsController < ApplicationController
  before_action :logged_in_user

  def index
    redirect_to action: :shopify_sales_receipts
  end

  def shopify_sales_receipts
    @shopify_sales_receipts = ShopifySalesReceipt.retail.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def shopify_costs
    @shopify_costs = ShopifySalesCost.retail.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def wholesale_shopify_sales_receipts
    @wholesale_shopify_sales_receipts = ShopifySalesReceipt.wholesale.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def wholesale_shopify_costs
    @wholesale_shopify_costs = ShopifySalesCost.wholesale.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def shopify_refunds
    @shopify_refunds = ShopifyRefund.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def vend_costs
    @vend_costs = DailyVendCost.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def vend_sales_receipts
    @vend_sales = DailyVendSale.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def vend_inventory_transfers
    @vend_inventory_transfers = DailyVendConsignment.order('date DESC').paginate(page: params[:page], per_page: 20)
  end
end

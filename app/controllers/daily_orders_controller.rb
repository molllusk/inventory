class DailyOrdersController < ApplicationController
  before_action :logged_in_user

  def index
    @daily_orders = DailyOrder.order('date DESC').paginate(page: params[:page], per_page: 60)
  end

  def show
    @daily_order = DailyOrder.find(params[:id])
  end

  def po
    @daily_order = DailyOrder.find(params[:daily_order_id])
    respond_to do |format|
      format.html do
        render :layout => false
      end
      format.pdf do
        file = @daily_order.display_po.gsub(/\s+/,'_') + '.pdf'
        send_data @daily_order.to_pdf, filename: file, type: 'application/pdf; charset=utf-8; header=present'
      end
    end
  end
end

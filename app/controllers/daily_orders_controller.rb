# frozen_string_literal: true

class DailyOrdersController < ApplicationController
  before_action :logged_in_user
  before_action :load_daily_order

  def show; end

  def po
    respond_to do |format|
      format.html do
        render layout: false
      end
      format.pdf do
        send_data @daily_order.to_pdf, filename: @daily_order.pdf_filename, type: 'application/pdf; charset=utf-8; header=present'
      end
      format.csv do
        send_data(
          @daily_order.to_csv,
          filename: @daily_order.csv_filename,
          type: 'text/csv; charset=utf-8; header=present'
        )
      end
    end
  end

  def cancel
    if @daily_order.cancel
      @daily_order.daily_inventory_transfer.delete_qbo_journal_entry
      @daily_order.daily_inventory_transfer.post_to_qbo
      flash[:success] = "Order #{@daily_order.display_po} has been canceled! Please confirm and complete any additional cancellation tasks (restock etc)."
    else
      flash[:danger] = "There was an error canceling order #{@daily_order.display_po}. Please try again."
    end

    redirect_to daily_order_path(@daily_order)
  end

  private

  def load_daily_order
    @daily_order = DailyOrder.find(params[:id] || params[:daily_order_id])
  end
end

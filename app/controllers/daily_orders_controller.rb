# frozen_string_literal: true

class DailyOrdersController < ApplicationController
  before_action :logged_in_user

  def show
    @daily_order = DailyOrder.find(params[:id])
  end

  def po
    @daily_order = DailyOrder.find(params[:daily_order_id])
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
end

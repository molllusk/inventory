# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :logged_in_user

  def index; end

  def generate_otb
    dates = params[:generate]

    GenerateOtbReport.perform_async(dates[:start], dates[:end])
    puts [dates[:start], dates[:end]]
    flash[:success] = 'The OTB Report is generating and will be emailed to John and Joseph when it finishes'

    redirect_to action: :index
  end

  def generate_products
    GenerateProductsReport.perform_async
    flash[:success] = 'The Product Inventory Report is generating and will be emailed to Johanna, John, and Joseph when it finishes'

    redirect_to action: :index
  end
end

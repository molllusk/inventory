class ReportsController < ApplicationController
  before_action :logged_in_user

  def index
  end

  def generate
    dates = params[:generate]

    GenerateSalesReport.perform_async(dates[:start], dates[:end])
    puts [dates[:start], dates[:end]]
    flash[:success] = 'The report is generating and will be emailed to john@mollusksurfshop.com when it finishes'

    redirect_to action: :index
  end
end

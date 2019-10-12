class DailyOrderThresholdsController < ApplicationController
  before_action :logged_in_user

  def index
    @inventory_thresholds = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL)
  end
end

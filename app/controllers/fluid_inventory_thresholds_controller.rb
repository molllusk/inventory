class FluidInventoryThresholdsController < ApplicationController
  before_action :logged_in_user

  def index
    @inventory_thresholds = GoogleClient.sheet_values(GoogleClient::FILL_LEVEL)
    @inventory_thresholds_old = FluidInventoryThreshold.all.order(:product_type)
  end
end

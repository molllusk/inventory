class FluidInventoryThresholdsController < ApplicationController
  before_action :logged_in_user

  def index
    @inventory_thresholds = FluidInventoryThreshold.all
  end
end

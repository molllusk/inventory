# frozen_string_literal: true

class FluidInventoryUpdatesController < ApplicationController
  before_action :logged_in_user

  def index
    @filterrific = initialize_filterrific(
      FluidInventoryUpdate,
      params[:filterrific]
    ) or return

    @fluid_inventory_updates = @filterrific.find.page(params[:page])
  end
end

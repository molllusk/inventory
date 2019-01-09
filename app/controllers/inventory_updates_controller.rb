class InventoryUpdatesController < ApplicationController
  def index
    @filterrific = initialize_filterrific(
      InventoryUpdate,
      params[:filterrific]
    ) or return

    @inventory_updates = @filterrific.find.page(params[:page])
  end
end

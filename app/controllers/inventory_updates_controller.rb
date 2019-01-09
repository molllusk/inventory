class InventoryUpdatesController < ApplicationController
  def index
    # @filterrific = initialize_filterrific(
    #   InventoryUpdate,
    #   params[:filterrific]
    # ) or return

    # @updates = @filterrific.find.page(params[:page])
    @updates = InventoryUpdate.all
  end
end

# frozen_string_literal: true

class InventoryUpdatesController < ApplicationController
  before_action :logged_in_user

  def index
    @filterrific = initialize_filterrific(
      InventoryUpdate,
      params[:filterrific]
    ) or return

    @inventory_updates = @filterrific.find.page(params[:page])
  end
end

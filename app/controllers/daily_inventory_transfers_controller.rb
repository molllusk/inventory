# frozen_string_literal: true

class DailyInventoryTransfersController < ApplicationController
  def index
    @daily_inventory_transfers = DailyInventoryTransfer.order('date DESC').paginate(page: params[:page], per_page: 20)
  end
end

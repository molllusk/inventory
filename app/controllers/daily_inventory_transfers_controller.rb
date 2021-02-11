# frozen_string_literal: true

class DailyInventoryTransfersController < ApplicationController
  def index
    @daily_inventory_transfers = DailyInventoryTransfer.order('date DESC').paginate(page: params[:page], per_page: 20)
  end

  def cancel
    @daily_inventory_transfer = DailyInventoryTransfer.find(params[:id] || params[:daily_inventory_transfer_id])
    if @daily_inventory_transfer.cancel
      flash[:success] = "All orders for this daily inventory transfer have been canceled! Please confirm and complete any additional cancellation tasks (restock, deleted QBO entries etc)."
    else
      flash[:danger] = "There was an error while cancelling orders for this daily inventory transfer. Please try again."
    end

    redirect_to daily_inventory_transfers_path
  end
end

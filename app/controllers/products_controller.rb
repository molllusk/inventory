# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :logged_in_user

  def index
    @filterrific = initialize_filterrific(
      Product,
      params[:filterrific]
    ) or return

    @products = @filterrific.find.page(params[:page])
  end

  def show
    @product = Product.find(params[:id])

    @inventory_updates = @product.inventory_updates.order('created_at DESC').paginate(page: params[:inventory_updates_page], per_page: 8)
    # We actually want this sort for orders, but created_at will do for now
    # sort { |a,b| b.daily_order.daily_inventory_transfer.date <=> a.daily_order.daily_inventory_transfer.date }
    @orders = @product.orders.order('created_at DESC').paginate(page: params[:orders_page], per_page: 8)
  end
end

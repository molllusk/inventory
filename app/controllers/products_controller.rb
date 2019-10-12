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

    @inventory_updates = @product.inventory_updates.order('created_at DESC').paginate(page: params[:page], per_page: 8)
    @fluid_inventory_updates = @product.fluid_inventory_updates.order('created_at DESC').paginate(page: params[:page], per_page: 8)
    @orders = @product.orders.paginate(page: params[:page], per_page: 8)
  end
end

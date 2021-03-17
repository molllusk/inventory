# frozen_string_literal: true

class ProductsController < ApplicationController
  before_action :logged_in_user
  before_action :load_product, except: %w[index shopify_issues]

  def index
    @filterrific = initialize_filterrific(
      Product,
      params[:filterrific]
    ) or return

    @products = @filterrific.find.page(params[:page])
  end

  def show
    # We actually want this sort for orders, but created_at will do for now
    # sort { |a,b| b.daily_order.daily_inventory_transfer.date <=> a.daily_order.daily_inventory_transfer.date }
    @orders = @product.orders.order('created_at DESC').paginate(page: params[:orders_page], per_page: 8)
  end

  def destroy
    if @product.destroy
      flash[:success] = 'Product deleted'
    else
      flash[:danger] = 'There was an error trying to delete this product'
    end

    redirect_to products_path
  end

  def shopify_issues
    @shopify_duplicates = ShopifyDuplicate.order('updated_at DESC').paginate(page: params[:shopify_duplicates_page], per_page: 15)
    @shopify_deletions = ShopifyDeletion.order('created_at DESC').paginate(page: params[:shopify_deletions_page], per_page: 15)
  end

  private

  def load_project
    @product = Product.find(params[:id])
  end
end

# frozen_string_literal: true

class ShopifyDataController < ApplicationController
  before_action :logged_in_user

  def destroy
    shopify_datum = ShopifyDatum.find(params[:shopify_datum_id])
    product = shopify_datum.product

    if shopify_datum.destroy
      flash[:success] = 'Shopify product data deleted'
    else
      flash[:danger] = 'There was an error trying to delete shopify data for this product'
    end

    redirect_to product_path(product)
  end
end

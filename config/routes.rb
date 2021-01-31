# frozen_string_literal: true

require 'sidekiq/web'
require 'sidekiq-scheduler/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq'
  root   'sessions#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'

  namespace :admin do
    root to: '#index'
  end

  namespace :api do
    namespace :v1 do
      resources :products do
        collection do
        end
      end
    end
  end

  namespace :callbacks do
    get '/quickbooks/authenticate', to: 'quickbooks#authenticate'
    get '/quickbooks/oauth_callback', to: 'quickbooks#oauth_callback'
  end

  resources :daily_inventory_transfers do
    put :cancel
  end

  resources :daily_orders do
    get :po
    put :cancel
  end
  resources :daily_order_thresholds

  resources :daily_reports do
    collection do
      get :shopify_sales_receipts
      get :shopify_costs
      get :shopify_refunds
      get :wholesale_shopify_sales_receipts
      get :wholesale_shopify_costs
      get :vend_sales_receipts
      get :vend_costs
      get :vend_inventory_transfers
      get :vend_sales_taxes
    end
  end

  resources :daily_vend_consignments
  resources :daily_vend_costs

  resources :daily_vend_sales do
    collection do
      get :sales_tax_csv
    end
  end

  resources :inventory_updates

  resources :products do
    collection do
      get :shopify_issues
    end
  end

  resources :reports do
    collection do
      get :generate_otb
      get :generate_products
    end
  end

  resources :shopify_data do
    delete :destroy
  end

  resources :shopify_refunds
  resources :shopify_sales_costs
  resources :shopify_sales_receipts
  resources :users

  resources :wholesale_orders do
    collection do
      get :post_to_sos
    end
  end
end

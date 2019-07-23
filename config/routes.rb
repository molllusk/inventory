Rails.application.routes.draw do
  root   'sessions#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'

  resources :inventory_updates
  resources :fluid_inventory_thresholds
  resources :fluid_inventory_updates
  resources :products
  resources :users
  resources :shopify_sales_receipts
  resources :shopify_refunds
  resources :shopify_sales_costs
  resources :daily_vend_consignments
  resources :daily_vend_costs
  resources :daily_vend_sales

  namespace :admin do
    root to: '#index'
  end

  namespace :callbacks do
    get '/quickbooks/authenticate', to: 'quickbooks#authenticate'
    get '/quickbooks/oauth_callback', to: 'quickbooks#oauth_callback'
  end

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
    end
  end
end

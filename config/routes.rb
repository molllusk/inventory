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
  resources :daily_vend_costs
  resources :daily_vend_sales

  namespace :admin do
    root to: '#index'
  end

  namespace :callbacks do
    get '/quickbooks/authenticate', to: 'quickbooks#authenticate'
    get '/quickbooks/oauth_callback', to: 'quickbooks#oauth_callback'
  end

  get '/daily_reports', to: 'daily_reports#index'
end

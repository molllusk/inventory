Rails.application.routes.draw do
  root   'sessions#new'
  get    '/login',   to: 'sessions#new'
  post   '/login',   to: 'sessions#create'
  delete '/logout',  to: 'sessions#destroy'

  resources :inventory_updates
  resources :fluid_inventory_thresholds
  resources :fluid_inventory_updates
  resources :products
  resources :shopify_sales_receipts
  resources :users

  namespace :admin do
    root to: '#index'
    get '/quickbooks/authenticate', to: 'admin_quickbooks#authenticate'
    get '/quickbooks/oauth_callback', to: 'admin_quickbooks#oauth_callback'
  end
end

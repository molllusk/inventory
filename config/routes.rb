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
end

Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  get :display, to: "home#display"
  get "display_from_token/:token", to: "home#display_from_token"
  get :redirect, to: 'home#redirect'
  get :google_callback, to: 'home#callback'
  resources :users, only: [:update]
  resources :devices, only: [:show]
end

Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  get :display, to: "home#display"
  get :redirect, to: 'home#redirect'
  get :callback, to: 'home#callback'
  resources :users, only: [:update]
end

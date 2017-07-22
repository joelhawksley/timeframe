Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  get :display, to: "home#display"
  resources :users, only: [:update]
end

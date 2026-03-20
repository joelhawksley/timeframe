# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "devices#index"

  resources :devices, only: [:create, :update, :destroy]

  get "accounts/me/displays/:name", to: "displays#show", as: :display

  get :status_page, to: "status#index"
  get :status, to: "status#show", defaults: {format: :json}
end

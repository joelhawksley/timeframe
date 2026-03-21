# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "devices#index"

  resources :devices, only: [:create, :update, :destroy]

  get "accounts/me/displays/:name", to: "displays#show", as: :display
  get "accounts/me/displays/:name/preview", to: "displays#preview", as: :display_preview
  get "accounts/me/displays/:name/screenshot", to: "displays#screenshot", as: :display_screenshot

  namespace :api, defaults: {format: :json} do
    get :setup, to: "trmnl#setup"
    get :display, to: "trmnl#display"
    post :log, to: "trmnl#log"
  end

  get :status_page, to: "status#index"
  get :status, to: "status#show", defaults: {format: :json}
end

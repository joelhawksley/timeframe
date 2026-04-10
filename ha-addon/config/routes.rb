# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  root to: "dashboard#index"
  get "setup", to: "setup#index"
  get "status", to: "status#index"
  post "claim_device", to: "dashboard#claim_device", as: :claim_device

  resources :accounts, only: [:create, :destroy] do
    resources :locations, only: [:create, :destroy] do
      resources :devices, only: [:create, :show, :update, :destroy] do
        get :confirmation_image, on: :member
        get :screenshot, on: :member
        post :regenerate_tokens, on: :member
        post :repair, on: :member
      end
    end
  end

  # Token-authenticated display routes for sessionless devices
  get "d/:id", to: "token_displays#show", as: :token_display
  get "d/:id/screenshot", to: "token_displays#screenshot", as: :token_display_screenshot

  # Signed, expiring screenshot URLs for TRMNL devices
  get "signed_screenshot/:sgid", to: "signed_screenshots#show", as: :signed_screenshot

  namespace :api, defaults: {format: :json} do
    get :setup, to: "trmnl#setup"
    get :display, to: "trmnl#display"
    post :log, to: "trmnl#log"
  end
end

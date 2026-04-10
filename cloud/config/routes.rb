# frozen_string_literal: true

Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  devise_for :users, controllers: {sessions: "users/sessions", magic_links: "users/magic_links"}

  authenticated :user do
    root to: "dashboard#index", as: :authenticated_root
  end

  unauthenticated do
    devise_scope :user do
      root to: "users/sessions#new"
    end
  end

  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"
  delete "account", to: "users#destroy", as: :delete_user_account
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
    resources :calendars, only: [:index, :new, :create, :destroy]
    resources :google_accounts, only: [:destroy]
  end

  # Token-authenticated display routes for sessionless devices
  get "d/:id", to: "token_displays#show", as: :token_display
  get "d/:id/screenshot", to: "token_displays#screenshot", as: :token_display_screenshot

  # Signed, expiring screenshot URLs for TRMNL devices
  get "signed_screenshot/:sgid", to: "signed_screenshots#show", as: :signed_screenshot

  # Google OAuth callbacks
  get "auth/google_oauth2/callback", to: "google_accounts#create"
  get "auth/failure", to: redirect("/")

  # Google Calendar push notification webhook
  post "webhooks/google_calendar", to: "webhooks#google_calendar"

  namespace :api, defaults: {format: :json} do
    get :setup, to: "trmnl#setup"
    get :display, to: "trmnl#display"
    post :log, to: "trmnl#log"
  end
end

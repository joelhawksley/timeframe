# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"
  get :thirteen, to: "home#thirteen"
  get :mira, to: "home#mira"
  get :logs, to: "home#logs"
  get :weather_logs, to: "home#weather_logs"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"
  resources :google_calendars, only: [:update]
end

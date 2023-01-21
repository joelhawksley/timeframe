# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"
  get :thirteen, to: "home#thirteen"
  get :sonos, to: "home#sonos"
  get :mira, to: "home#mira"
  get :logs, to: "home#logs"
  get :weather_logs, to: "home#weather_logs"
  get :calendars, to: "home#calendars"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"
  resources :google_calendars, only: [:update]
end

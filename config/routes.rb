# frozen_string_literal: true

Rails.application.routes.draw do
  get :thirteen, to: "home#thirteen"

  get :mira, to: "home#mira"
  get :sonos, to: "home#sonos"
  get :timeline, to: "home#timeline"

  root to: "home#index"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"
  resources :google_calendars, only: [:update]

  get :logs, to: "home#logs"
  get :weather_data, to: "home#weather_data"
  get :calendar_data, to: "home#calendar_data"
end

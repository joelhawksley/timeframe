# frozen_string_literal: true

Rails.application.routes.draw do
  get :thirteen, to: "home#thirteen"
  get :mira, to: "home#mira"

  root to: "home#index"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"

  get :logs, to: "home#logs"
  get :weather_data, to: "home#weather_data"
end

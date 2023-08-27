# frozen_string_literal: true

Rails.application.routes.draw do
  get :thirteen, to: "displays#thirteen"
  get :mira, to: "displays#mira"

  root to: "home#index"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"

  get :logs, to: "home#logs"
  get :calendar_data, to: "home#calendar_data"
  get :weather_data, to: "home#weather_data"
end

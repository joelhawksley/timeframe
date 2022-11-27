# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :users
  root to: "home#index"
  get :redirect, to: "home#redirect"
  get :google_callback, to: "home#callback"
  resources :users, only: [:update]
  resources :templates, only: [:show]
  resources :google_calendars, only: [:update]
  resources :google_accounts, only: [:update]
end

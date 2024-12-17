# frozen_string_literal: true

Rails.application.routes.draw do
  get :thirteen, to: "displays#thirteen"
  get :mira, to: "displays#mira"

  root to: "home#index"
  get :logs, to: "home#logs"
end

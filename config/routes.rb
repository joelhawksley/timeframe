# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "status#index"
  get :thirteen, to: "displays#thirteen"
  get :mira, to: "displays#mira"
  get :status, to: "status#show", defaults: {format: :json}
end

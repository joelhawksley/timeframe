# frozen_string_literal: true

require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  get :thirteen, to: "displays#thirteen"
  get :mira, to: "displays#mira"

  root to: "home#index"
  get :logs, to: "home#logs"

  mount Sidekiq::Web => "/sidekiq"
end

# frozen_string_literal: true

source "https://rubygems.org"
ruby "4.0.2"

if ENV["RAILS_ENV"] == "production" || ENV["CI"]
  gem "timeframe-core", git: "https://github.com/timeframe/core", require: "timeframe_core"
else
  gem "timeframe-core", path: "../core", require: "timeframe_core"
end

gem "anyway_config"
gem "csv"
gem "extlz4"
gem "ferrum"
gem "httparty"
gem "mini_magick"
gem "pg"
gem "propshaft"
gem "puma"
gem "puma-rufus-scheduler"
gem "rack-attack"
gem "rails", "~> 8"
gem "rufus-scheduler"
gem "warden"
gem "websocket-client-simple"
gem "bootstrap", "~> 5.3"
gem "dartsass-rails"

group :development, :test do
  gem "overcommit"
  gem "m"
  gem "minitest"
  gem "minitest-mock"
  gem "standard"
end

group :test do
  gem "capybara"
  gem "cuprite"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

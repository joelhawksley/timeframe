# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.2.2"

gem "connection_pool"
gem "httparty"
gem "pg"
gem "puma"
gem "rails", "~> 7.1"
gem "redis"
gem "sidekiq", "7.3.2" # until compat with sidekiq-cron is fixed
gem "sidekiq-cron"
gem "slim"
gem "tenkit", git: "https://github.com/joelhawksley/tenkit", branch: "add-alerts"
gem "time_difference"

group :development, :test do
  gem "overcommit"
  gem "m"
  gem "minitest"
  gem "standard"
  gem "pry-rails"
end

group :test do
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

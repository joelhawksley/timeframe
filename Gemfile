# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.2.2"

gem "connection_pool"
gem "httparty"
gem "puma"
gem "rails", "~> 8"
gem "solid_queue", "~> 1.1"
gem "sqlite3"
gem "tenkit", git: "https://github.com/joelhawksley/tenkit", branch: "add-alerts"
gem "time_difference"

group :development, :test do
  gem "overcommit"
  gem "m"
  gem "minitest"
  gem "standard"
end

group :test do
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end

# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.0.3"

gem "dotenv-rails"
gem "google-api-client", require: ["google/apis/calendar_v3", "google/apis/people_v1"]
gem "httparty"
gem "sqlite3"
gem "puma"
gem "rails", "~> 7.1"
gem "slim"
gem "tenkit", git: "https://github.com/joelhawksley/tenkit", branch: "add-alerts"
gem "time_difference"
gem "view_component"

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

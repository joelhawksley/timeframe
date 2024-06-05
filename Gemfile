# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.2.2"

gem "google-api-client", require: ["google/apis/calendar_v3", "google/apis/people_v1"]
gem "httparty"
gem "pg"
gem "puma"
gem "rails", "~> 7.1"
gem "slim"
gem "solid_queue"
gem "request_store"
gem "tenkit", git: "https://github.com/joelhawksley/tenkit", branch: "add-alerts"
gem "time_difference"

group :development do
  gem "rack-mini-profiler"
end

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

# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.0.3"

gem "dotenv-rails"
gem "google-api-client", require: ["google/apis/calendar_v3", "google/apis/people_v1"]
gem "httparty"
gem "pg"
gem "puma"
gem "rails", "~> 7"
gem "sass-rails"
gem "slim"
gem "tenkit"
gem "view_component"

group :development, :test do
  gem "overcommit"
  gem "minitest"
  gem "standard"
  gem "pry-rails"
end

group :test do
  gem "simplecov", require: false
end

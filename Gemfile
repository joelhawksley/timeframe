# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.0.3"

gem "dotenv-rails"
gem "google-api-client", "~> 0.11", require: ["google/apis/calendar_v3", "google/apis/people_v1"]
gem "httparty"
gem "pg", "~> 1.1"
gem "puma", "~> 5.6"
gem "rails", "~> 7"
gem "sass-rails", "~> 6.0"
gem "slim"
gem "tenkit"
gem "view_component", "3.0.0.rc2"

group :development, :test do
  gem "minitest"
  gem "standard"
  gem "pry-rails"
end

group :test do
  gem "simplecov", require: false
end

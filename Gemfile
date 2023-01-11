# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.0.3"

gem "bootstrap-sass"
gem "dotenv-rails"
gem "font-awesome-sass", "~> 6.2.1"
gem "google-api-client", "~> 0.11", require: ["google/apis/calendar_v3", "google/apis/people_v1", "google/apis/gmail_v1"]
gem "htmx-rails"
gem "httparty"
gem "mime-types-data", "3.2021.1115" # TODO: See https://github.com/mime-types/mime-types-data/pull/50
gem "pg", "~> 1.1"
gem "puma", "~> 4.3"
gem "rails", "~> 7"
gem "sass-rails", "~> 5.0"
gem "slim"
gem "visionect-ruby", git: "https://github.com/joelhawksley/visionect-ruby.git"

group :development, :test do
  gem "minitest"
  gem "standard"
  gem "pry-rails"
end

group :test do
  gem "simplecov", require: false
end

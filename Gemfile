# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.1.0"

gem "bootstrap-sass"
gem "devise"
gem "dotenv-rails"
gem "exception_notification"
gem "font-awesome-rails"
gem "google-api-client", "~> 0.11", require: ["google/apis/calendar_v3", "google/apis/people_v1", "google/apis/gmail_v1"]
gem "httparty"
gem "imgkit"
gem "multipart-post"
gem "nokogiri", "1.11.4"
gem "pg", "~> 1.1"
gem "puma", "~> 4.3"
gem "rails", "~> 6.1"
gem "rack-cache"
gem "sass-rails", "~> 5.0"
gem "slim"
gem "uglifier", ">= 1.3.0"
gem "visionect-ruby", git: "https://github.com/joelhawksley/visionect-ruby.git"

group :development, :test do
  gem "capybara"
  gem "minitest"
  gem "standard"
  gem "pry-rails"
  gem "wkhtmltoimage-binary"
end

group :test do
  gem "simplecov", require: false
end

# frozen_string_literal: true

source "https://rubygems.org"
ruby "3.4.3"

gem "csv"
gem "httparty"
gem "puma"
gem "puma-rufus-scheduler"
gem "rails", "~> 8"
gem "rufus-scheduler"
gem "tenkit", git: "https://github.com/superbasicxyz/tenkit", tag: "v0.0.7"

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

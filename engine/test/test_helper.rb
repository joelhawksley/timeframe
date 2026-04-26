# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  command_name "tests"
  enable_coverage :branch
  add_filter "test/"
  add_filter "lib/"
  add_filter "config/"
  add_filter "app/channels/"
  add_filter "app/controllers/"
  add_filter "app/jobs/"
  add_filter "app/lib/screenshot_service.rb"
  add_filter "app/lib/visionect_protocol/proxy.rb"
  add_filter "app/lib/visionect_protocol/server.rb"
  add_filter "app/models/account_user.rb"
end
SimpleCov.minimum_coverage line: 100, branch: 95

ENV["RAILS_ENV"] = "test"
require File.expand_path("dummy/config/environment", __dir__)
require "minitest/autorun"
require "minitest/mock"
require "active_support/testing/time_helpers"

DEPLOY_TIME = Time.now.to_i

def test_user
  @test_user ||= begin
    account = Account.find_or_create_by!(name: "Test")
    user = User.find_or_create_by!(email: "test@timeframe.local")
    user.accounts << account unless user.accounts.include?(account)
    account.locations.find_or_create_by!(name: "Test Location") do |l|
      l.latitude = 38.4937
      l.longitude = -98.7675
      l.time_zone = "America/Chicago"
    end
    user
  end
end

def test_location
  @test_location ||= test_user.accounts.first.locations.first
end

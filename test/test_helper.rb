# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  enable_coverage :branch
end
SimpleCov.minimum_coverage line: 100, branch: 100

ENV["RAILS_ENV"] = "test"
require File.expand_path("../../config/environment", __FILE__)
require "minitest/autorun"
require "minitest/mock"
require "active_support/testing/time_helpers"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
end

# Seed HomeAssistantConfigApi cache with test data so time_zone is available in all tests
Rails.cache.write(
  "#{DEPLOY_TIME}home_assistant_config_api",
  {
    last_fetched_at: Time.now.utc,
    response: {
      latitude: 38.4937,
      longitude: -98.7675,
      time_zone: "America/Chicago",
      unit_system: {
        temperature: "°F",
        wind_speed: "mph",
        accumulated_precipitation: "in"
      }
    }
  }.to_json
)

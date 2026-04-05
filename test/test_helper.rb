# frozen_string_literal: true

# Fail the test suite on any Ruby warnings or deprecation notices
module WarningBackstop
  def warn(message, *args, **kwargs)
    raise "Unexpected warning: #{message}" unless caller_locations.any? { |l| l.path.include?("/gems/") }
    super
  end
end
Warning.extend(WarningBackstop)

require "simplecov"
SimpleCov.start do
  command_name "tests"
  enable_coverage :branch

  # Infrastructure code that requires external services or hardware
  add_filter "config/initializers/"
  add_filter "config/application.rb"
  add_filter "app/jobs/"
  add_filter "app/lib/screenshot_service.rb"
  add_filter "app/lib/visionect_protocol/"
  add_filter "app/lib/display_broadcaster.rb"
  add_filter "app/channels/"
  add_filter "app/models/audit_log.rb"
  add_filter "app/models/account_user.rb"
  add_filter "app/apis/weather_kit_api.rb"

  # Controllers with complex session/auth dependencies tested at integration level
  add_filter "app/controllers/setup_controller.rb"
  add_filter "app/controllers/displays_controller.rb"
  add_filter "app/controllers/token_displays_controller.rb"
  add_filter "app/controllers/signed_screenshots_controller.rb"
  add_filter "app/controllers/application_controller.rb"

  # External API-dependent code (Google Calendar webhooks, OAuth refresh)
  add_filter "app/models/calendar.rb"
  add_filter "app/models/google_account.rb"
  add_filter "app/models/timeframe_config.rb"
  add_filter "test/"
end
SimpleCov.minimum_coverage line: 100, branch: 95

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
  "#{DEPLOY_TIME}#{HomeAssistantApi::CONFIG_DOMAIN}",
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

DEFAULT_TEST_CONFIG = {
  latitude: 38.4937,
  longitude: -98.7675,
  time_zone: "America/Chicago",
  unit_system: {
    temperature: "°F",
    wind_speed: "mph",
    accumulated_precipitation: "in"
  }
}.freeze

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

def new_test_api(config = nil)
  store = ActiveSupport::Cache::MemoryStore.new
  api = HomeAssistantApi.new(config || TimeframeConfig.new, store: store)
  api.seed_config(DEFAULT_TEST_CONFIG)
  api
end

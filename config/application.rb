# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Timeframe
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0
    config.local = YAML.load_file(Rails.root.join("config.yml"))

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.secret_key_base = ENV["SECRET_KEY_BASE"]

    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    config.hosts << "hawksley-server.local"
    config.hosts << "timeframetesting.com"

    config.active_record.legacy_connection_handling = false

    config.after_initialize do
      if ENV["RUN_BG"]
        Thread.new do
          while true do
            SonosService.fetch

            sleep(2)
          end
        end

        Thread.new do
          while true do
            WeatherKitService.fetch

            sleep(60)
          end
        end

        Thread.new do
          while true do
            WeatherAlertService.fetch

            sleep(300)
          end
        end

        Thread.new do
          while true do
            GoogleService.call

            sleep(60)
          end
        end
      end
    end
  end
end

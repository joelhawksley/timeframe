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
# require "sprockets/railtie"
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

    config.hosts << "hawksley-server.local"
    config.hosts << "timeframetesting.com"

    # :nocov:
    config.after_initialize do
      def run_in_bg(interval, &block)
        Thread.new do
          loop do
            begin
              yield
            rescue => e
              Log.create(
                globalid: "Timeframe.after_initialize",
                event: "background thread error",
                message: e.message + e.backtrace.join("\n")
              )
            end

            sleep(interval)
          end
        end
      end

      if ENV["RUN_BG"]
        run_in_bg(1) { SonosSystem.fetch }
        run_in_bg(1) { HomeAssistantHome.fetch }
        run_in_bg(60) { WeatherKitAccount.fetch }
        run_in_bg(60) do
          ActiveRecord::Base.connection_pool.with_connection do
            GoogleAccount.all.each(&:fetch)
          end
        end
      end
    end
    # :nocov:
  end
end

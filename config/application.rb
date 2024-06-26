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

require "redis"

module Timeframe
  class Application < Rails::Application
    def self.redis
      @redis ||= ConnectionPool::Wrapper.new do
        Redis.new
      end
    end

    config.local = YAML.load_file(Rails.root.join("config.yml")).freeze

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.secret_key_base = ENV["SECRET_KEY_BASE"]

    config.hosts << "hawksley-server.local"
    config.hosts << "timeframetesting.com"
  end
end

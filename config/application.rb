# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Timeframe
  class Application < Rails::Application
    config.cache_store = :file_store, Rails.root.join("tmp/cache/").to_s
    config.action_controller.perform_caching = false

    config.local = YAML.load_file(Rails.root.join("config.yml")).freeze

    config.secret_key_base = "foo" # Not needed as app runs behind firewall

    config.hosts << "hawksley-server.local"
    config.hosts << "timeframetesting.com"
  end
end

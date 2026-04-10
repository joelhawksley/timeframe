# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "action_mailer/railtie"
require "action_cable/engine"

Bundler.require(*Rails.groups)

module HaAddon
  class Application < Rails::Application
    config.autoloader = :zeitwerk

    config.anyway_config.future.use :unwrap_known_environments

    config.cache_store = :file_store, Rails.root.join("tmp/cache/").to_s
    config.action_controller.perform_caching = false

    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "foo")

    config.hosts.clear

    # Warden middleware for session-based auth (auto-sign-in)
    config.middleware.use Warden::Manager do |manager|
      manager.default_strategies :none
      manager.failure_app = ->(env) { [401, {"Content-Type" => "text/plain"}, ["Unauthorized"]] }

      manager.serialize_into_session(:user) { |user| user.id }
      manager.serialize_from_session(:user) { |id| User.find_by(id: id) }
    end
  end
end

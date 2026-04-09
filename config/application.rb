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

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Timeframe
  class Application < Rails::Application
    config.autoloader = :zeitwerk

    Rails.autoloaders.each do |autoloader|
      autoloader.inflector.inflect("lz4_block" => "LZ4Block")
    end

    # Allow anyway_config to load flat YAML files (no environment nesting required)
    config.anyway_config.future.use :unwrap_known_environments

    def self.multi_tenant?
      require_relative "../app/models/timeframe_config"
      !TimeframeConfig.new.home_assistant?
    end

    config.cache_store = :file_store, Rails.root.join("tmp/cache/").to_s
    config.action_controller.perform_caching = false

    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE", "foo")

    config.hosts.clear

    config.action_mailer.default_url_options = {host: ENV.fetch("APP_HOST", "localhost"), port: ENV.fetch("PORT", 3000)}
    config.action_mailer.delivery_method = ENV["MAILGUN_SMTP_SERVER"] ? :smtp : :test
    if ENV["MAILGUN_SMTP_SERVER"]
      config.action_mailer.smtp_settings = {
        address: ENV["MAILGUN_SMTP_SERVER"],
        port: ENV.fetch("MAILGUN_SMTP_PORT", 587).to_i,
        user_name: ENV["MAILGUN_SMTP_LOGIN"],
        password: ENV["MAILGUN_SMTP_PASSWORD"],
        authentication: :plain,
        enable_starttls_auto: true
      }
    end

    if multi_tenant?
      config.active_job.queue_adapter = :good_job

      config.good_job.enable_cron = true
      config.good_job.cron = {
        sync_calendar_events: {
          cron: "*/15 * * * *",
          class: "SyncAllCalendarsJob"
        },
        cleanup_past_events: {
          cron: "0 3 * * *",
          class: "CleanupPastEventsJob"
        },
        renew_google_webhooks: {
          cron: "0 */6 * * *",
          class: "RenewGoogleWebhooksJob"
        }
      }
    end
  end
end

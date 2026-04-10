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

module Cloud
  class Application < Rails::Application
    config.autoloader = :zeitwerk

    config.secret_key_base = ENV.fetch("SECRET_KEY_BASE")

    config.hosts.clear

    config.action_mailer.default_url_options = {host: ENV.fetch("APP_HOST", "localhost"), port: ENV.fetch("PORT", 3000)}
    config.action_mailer.delivery_method = ENV["SES_SMTP_ADDRESS"] ? :smtp : :test
    if ENV["SES_SMTP_ADDRESS"]
      config.action_mailer.smtp_settings = {
        address: ENV["SES_SMTP_ADDRESS"],
        port: ENV.fetch("SES_SMTP_PORT", 587).to_i,
        user_name: ENV["SES_SMTP_USERNAME"],
        password: ENV["SES_SMTP_PASSWORD"],
        authentication: :login,
        enable_starttls_auto: true
      }
    end

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

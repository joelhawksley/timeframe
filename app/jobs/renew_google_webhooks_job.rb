# frozen_string_literal: true

class RenewGoogleWebhooksJob < ApplicationJob
  queue_as :default

  def perform
    # Renew webhooks expiring within the next day
    Calendar.with_expiring_webhooks.find_each(&:register_webhook!)

    # Register webhooks for any Google calendars that don't have one yet
    Calendar.without_webhooks.find_each(&:register_webhook!)
  end
end

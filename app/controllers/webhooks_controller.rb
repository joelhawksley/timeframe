# frozen_string_literal: true

class WebhooksController < ApplicationController
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :auto_sign_in_default_user!, raise: false
  skip_before_action :verify_authenticity_token, only: [:google_calendar]

  def google_calendar
    channel_id = request.headers["X-Goog-Channel-ID"]
    resource_state = request.headers["X-Goog-Resource-State"]
    token = request.headers["X-Goog-Channel-Token"]

    return head :bad_request if channel_id.blank?

    # Google sends a "sync" notification when the watch is first created — acknowledge it
    return head :ok if resource_state == "sync"

    calendar = Calendar.find_by(webhook_channel_id: channel_id)
    return head :not_found unless calendar

    # Verify the token matches
    unless ActiveSupport::SecurityUtils.secure_compare(token.to_s, calendar.webhook_verification_token)
      return head :forbidden
    end

    SyncGoogleCalendarJob.perform_later(calendar.id)

    head :ok
  end
end

# frozen_string_literal: true

class SyncGoogleAccountCalendarsJob < ApplicationJob
  queue_as :default

  def perform(google_account_id)
    google_account = GoogleAccount.find_by(id: google_account_id)
    return unless google_account

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = google_account.valid_access_token

    calendar_list = service.list_calendar_lists

    calendar_list.items&.each do |gcal|
      calendar = google_account.calendars.find_or_initialize_by(external_id: gcal.id)
      calendar.update!(
        account: google_account.account,
        name: gcal.summary || gcal.id,
        source_type: "google"
      )

      SyncGoogleCalendarJob.perform_later(calendar.id)
      calendar.register_webhook! if calendar.webhook_channel_id.blank?
    end
  end
end

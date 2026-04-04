# frozen_string_literal: true

class SyncGoogleCalendarJob < ApplicationJob
  queue_as :default

  def perform(calendar_id)
    calendar = Calendar.find_by(id: calendar_id)
    return unless calendar&.google?

    google_account = calendar.google_account
    return unless google_account

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = google_account.valid_access_token

    time_min = Time.current.beginning_of_day.iso8601
    time_max = 40.days.from_now.end_of_day.iso8601

    events = service.list_events(
      calendar.external_id,
      time_min: time_min,
      time_max: time_max,
      single_events: true,
      order_by: "startTime"
    )

    seen_external_ids = []

    events.items&.each do |event|
      next if event.status == "cancelled"

      external_id = event.id
      seen_external_ids << external_id

      starts_at = event.start&.date_time || DateTime.parse(event.start&.date.to_s).in_time_zone("UTC")
      ends_at = event.end&.date_time || DateTime.parse(event.end&.date.to_s).in_time_zone("UTC")
      start_timezone = event.start&.time_zone
      end_timezone = event.end&.time_zone

      calendar_event = calendar.calendar_events.find_or_initialize_by(external_id: external_id)
      calendar_event.update!(
        title: event.summary,
        description: event.description,
        location: event.location,
        starts_at: starts_at,
        ends_at: ends_at,
        start_timezone: start_timezone,
        end_timezone: end_timezone
      )
    end

    # Remove events that are no longer in the API response
    calendar.calendar_events
      .where.not(external_id: seen_external_ids)
      .where("starts_at >= ?", Time.current.beginning_of_day)
      .delete_all

    calendar.update!(last_synced_at: Time.current)

    AuditLog.create!(
      subject: calendar,
      event_type: "sync_attempted",
      result_type: "success",
      metadata: {source: "google", events_count: seen_external_ids.size}
    )
  rescue => e
    Rails.logger.error("[SyncGoogleCalendar] Failed for calendar #{calendar_id}: #{e.message}")
    if calendar
      AuditLog.create!(
        subject: calendar,
        event_type: "sync_attempted",
        result_type: "error",
        metadata: {source: "google", error: e.message}
      )
    end
  end
end

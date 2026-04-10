# frozen_string_literal: true

class SyncIcsCalendarJob < ApplicationJob
  queue_as :default

  def perform(calendar_id)
    calendar = Calendar.find_by(id: calendar_id)
    return unless calendar&.url?

    response = HTTParty.get(calendar.url, timeout: 30)
    ics_calendars = Icalendar::Calendar.parse(response.body)

    seen_external_ids = []
    time_horizon = 40.days.from_now.end_of_day

    ics_calendars.each do |ics_calendar|
      ics_calendar.events.each do |event|
        starts_at = event.dtstart&.to_time
        ends_at = event.dtend&.to_time

        next unless starts_at
        next if ends_at && ends_at < Time.current.beginning_of_day
        next if starts_at > time_horizon

        ends_at ||= starts_at

        external_id = event.uid.to_s
        next if external_id.blank?

        seen_external_ids << external_id

        start_timezone = event.dtstart.respond_to?(:ical_params) ? event.dtstart.ical_params.fetch("TZID", [nil]).first : nil
        end_timezone = event.dtend&.respond_to?(:ical_params) ? event.dtend.ical_params.fetch("TZID", [nil]).first : nil

        calendar_event = calendar.calendar_events.find_or_initialize_by(external_id: external_id)
        calendar_event.update!(
          title: event.summary.to_s,
          description: event.description.to_s.presence,
          location: event.location.to_s.presence,
          starts_at: starts_at,
          ends_at: ends_at,
          start_timezone: start_timezone,
          end_timezone: end_timezone
        )
      end
    end

    # Remove events that are no longer in the feed
    calendar.calendar_events
      .where.not(external_id: seen_external_ids)
      .where("starts_at >= ?", Time.current.beginning_of_day)
      .delete_all

    calendar.update!(last_synced_at: Time.current)

    AuditLog.create!(
      subject: calendar,
      event_type: "sync_attempted",
      result_type: "success",
      metadata: {source: "ics", events_count: seen_external_ids.size}
    )
  rescue => e
    Rails.logger.error("[SyncIcsCalendar] Failed for calendar #{calendar_id}: #{e.message}")
    if calendar
      AuditLog.create!(
        subject: calendar,
        event_type: "sync_attempted",
        result_type: "error",
        metadata: {source: "ics", error: e.message}
      )
    end
  end
end

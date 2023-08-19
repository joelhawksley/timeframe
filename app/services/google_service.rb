# frozen_string_literal: true

require "yaml"

class GoogleService
  def self.call
    events = new.events

    if events.any?
      Value.find_by_key("calendar_events").update!(value: events)
    else
      Log.create(
        globalid: "GoogleService",
        event: "error_no_events",
        message: ""
      )
    end
  rescue => e
    Log.create(
      globalid: "GoogleService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  attr_reader :events

  def initialize
    @events = calendar_events
  end

  private

  def calendar_events
    events = CalendarService.calendar_events

    GoogleAccount.all.each do |google_account|
      client = GoogleAccount.client

      begin
        client.update!(
          refresh_token: google_account.refresh_token,
          access_token: google_account.access_token,
          expires_in: 3600
        )
      rescue => e
        Log.create(
          globalid: google_account.to_global_id,
          event: "client_refresh_error",
          message: e.message + e.backtrace.join("\n")
        )
      end

      service = Google::Apis::CalendarV3::CalendarService.new
      service.authorization = client

      begin
        calendars = service.list_calendar_lists.items
      rescue => e
        Log.create(
          globalid: google_account.to_global_id,
          event: "list_calendar_lists",
          message: e.message
        )
      end

      next unless calendars.present?

      Timeframe::Application.config.local["calendars"].each do |calendar_config|
        begin
          items = service.list_events(
            calendar_config["id"],
            single_events: true,
            order_by: "startTime",
            fields: "items/attendees,items/id,items/start,items/end,items/description,items/summary,items/location",
            time_min: (DateTime.now - 2.days).iso8601,
            time_max: (DateTime.now + 1.week).iso8601
          ).items

          events[google_account.email] ||= {}

          events[google_account.email][calendar_config["id"]] = {}

          items.each do |event|
            event_json = event.as_json

            next if
              event_json["description"].to_s.downcase.include?("timeframe-omit") || # hide timeframe-omit
                event_json["summary"] == "." || # hide . marker
                event_json["summary"] == "Out of office" ||
                event_json["attendees"].to_a.any? { _1["self"] && _1["response_status"] == "declined" } ||
                !event_json["summary"].present?

            events[google_account.email][calendar_config["id"]][event.id] = CalendarEvent.new(
              id: event_json["id"],
              location: event_json["location"],
              summary: event_json["summary"],
              description: event_json["description"],
              icon: calendar_config["icon"],
              letter: calendar_config["letter"],
              starts_at: event_json["start"]["date"] || event_json["start"]["date_time"],
              ends_at: event_json["end"]["date"] || event_json["end"]["date_time"]
            ).to_h
          end
        rescue => e
          Log.create(
            globalid: "GoogleService",
            event: "list_events_error",
            message: e.class.to_s + e.message + e.backtrace.join("\n") + calendar_config.to_json
          )
        end
      end
    end

    events
  end
end

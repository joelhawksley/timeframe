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
    events = Value.calendar_events

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

      events[google_account.email] = {}

      calendars.each_with_index do |calendar, _index|
        calendar_config = 
          Timeframe::Application.config.local["calendars"].find { _1["id"] == calendar.id }

        next unless calendar_config.present?

        time_max = calendar.summary == "Birthdays" ? (DateTime.now + 12.weeks).iso8601 : (DateTime.now + 1.weeks).iso8601

        service.list_events(
          calendar.id,
          single_events: true,
          order_by: "startTime",
          fields: "items/id,items/start,items/end,items/description,items/summary,items/location",
          time_min: (DateTime.now - 2.days).iso8601,
          time_max: time_max
        ).items.each do |event|
          own_attendee = event.attendees.to_a.find { |attendee| attendee.email == calendar.id }

          # exclude declined events
          next if own_attendee && own_attendee.response_status == "declined"

          # exclude blank events
          next unless event.summary.present?

          event_json = event.as_json

          start_i =
            if event_json["start"].key?("date")
              ActiveSupport::TimeZone[Timeframe::Application.config.local["timezone"]].parse(event_json["start"]["date"]).utc.to_i
            else
              ActiveSupport::TimeZone[Timeframe::Application.config.local["timezone"]].parse(event_json["start"]["date_time"]).utc.to_i
            end

          end_i =
            if event_json["end"].key?("date")
              # Subtract 1 second, as Google gives us the end date as the following day, not the end of the current day
              ActiveSupport::TimeZone[Timeframe::Application.config.local["timezone"]].parse(event_json["end"]["date"]).utc.to_i - 1
            else
              ActiveSupport::TimeZone[Timeframe::Application.config.local["timezone"]].parse(event_json["end"]["date_time"]).utc.to_i
            end

          next if
            event_json["description"].to_s.downcase.include?("timeframe-omit") || # hide timeframe-omit
              event_json["summary"] == "." || # hide . marker
              event_json["summary"] == "Out of office"

          multi_day = ((end_i - start_i) > 86_400)

          summary =
            if (1900..2100).cover?(event_json["description"].to_s.to_i)
              counter = Date.today.year - event_json["description"].to_s.to_i

              "#{event_json["summary"]} (#{counter})"
            else
              event_json["summary"]
            end

          calendar_event = CalendarEvent.new(
            id: event_json["id"],
            location: event_json["location"],
            summary: summary,
            calendar: calendar.summary,
            icon: calendar_config["icon"],
            letter: calendar_config["letter"],
            start_i: start_i,
            end_i: end_i,
            multi_day: multi_day,
            all_day: event_json["start"].key?("date") || multi_day
          )

          events[google_account.email][event.id] = calendar_event.to_h
        end
      end

      Log.create(
        globalid: google_account.to_global_id,
        event: "fetch_success",
        message: ""
      )
    end

    events
  end
end

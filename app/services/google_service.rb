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

      events[google_account.email] = {}

      Timeframe::Application.config.local["calendars"].each do |calendar_config|
        service.list_events(
          calendar_config["id"],
          single_events: true,
          order_by: "startTime",
          fields: "items/id,items/start,items/end,items/description,items/summary,items/location",
          time_min: (DateTime.now - 2.days).iso8601,
          time_max: (DateTime.now + 1.weeks).iso8601
        ).items.each do |event|
          own_attendee = event.attendees.to_a.find { |attendee| attendee.email == calendar_config["id"] }

          # exclude declined events
          next if own_attendee && own_attendee.response_status == "declined"

          # exclude blank events
          next unless event.summary.present?

          event_json = event.as_json

          next if
            event_json["description"].to_s.downcase.include?("timeframe-omit") || # hide timeframe-omit
              event_json["summary"] == "." || # hide . marker
              event_json["summary"] == "Out of office"

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

          events[google_account.email][event.id] = CalendarEvent.new(
            id: event_json["id"],
            location: event_json["location"],
            summary: event_json["summary"],
            description: event_json["description"],
            icon: calendar_config["icon"],
            letter: calendar_config["letter"],
            start_i: start_i,
            end_i: end_i,
            all_day: event_json["start"].key?("date") || ((end_i - start_i) > 86_400)
          ).to_h
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

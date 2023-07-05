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

  def self.config
    @config ||= YAML.load_file(Rails.root.join("config.yml"))
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
          self.class.config["calendars"].find { _1["id"] == calendar.id }

        next unless calendar_config.present?

        service.list_events(
          calendar.id,
          single_events: true,
          order_by: "startTime",
          time_min: (DateTime.now - 2.weeks).iso8601,
          time_max: (DateTime.now + 12.weeks).iso8601
        ).items.each do |event|
          own_attendee = event.attendees.to_a.find { |attendee| attendee.email == calendar.id }

          # exclude declined events
          next if own_attendee && own_attendee.response_status == "declined"

          # exclude blank events
          next unless event.summary.present?

          event_json = event.as_json

          start_i =
            if event_json["start"].key?("date")
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["start"]["date"]).utc.to_i
            else
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["start"]["date_time"]).utc.to_i
            end

          end_i =
            if event_json["end"].key?("date")
              # Subtract 1 second, as Google gives us the end date as the following day, not the end of the current day
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["end"]["date"]).utc.to_i - 1
            else
              ActiveSupport::TimeZone[Timeframe::Application::LOCAL_TZ].parse(event_json["end"]["date_time"]).utc.to_i
            end

          next if
            event_json["description"].to_s.downcase.include?("timeframe-omit") || # hide timeframe-omit
              event_json["summary"] == "." || # hide . marker
              event_json["summary"] == "Out of office"

          weather =
            if event_json["description"].to_s.downcase.include?("timeframe-weather")
              Value
                .find_by_key("weather")
                .value["nws_hourly"].find { _1["start_i"] >= start_i }
            end

          multi_day = ((end_i - start_i) > 86_400)

          summary =
            if (1900..2100).cover?(event_json["description"].to_s.to_i)
              counter = Date.today.year - event_json["description"].to_s.to_i

              "#{event_json["summary"]} (#{counter})"
            else
              event_json["summary"]
            end

          events[google_account.email][event.id] = event_json.slice(
            "id",
            "start",
            "end",
            "location"
          ).merge(
            summary: summary,
            calendar: calendar.summary,
            icon: calendar_config["icon"],
            letter: calendar_config["letter"],
            start_i: start_i,
            end_i: end_i,
            weather: weather,
            multi_day: multi_day,
            all_day: event_json["start"].key?("date") || multi_day
          ).symbolize_keys!
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

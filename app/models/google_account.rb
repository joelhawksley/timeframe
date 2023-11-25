# frozen_string_literal: true

class GoogleAccount < ApplicationRecord
  def self.client
    Signet::OAuth2::Client.new(client_options)
  end

  def self.client_options
    {
      client_id: Timeframe::Application.config.local["google_client_id"],
      client_secret: Timeframe::Application.config.local["google_client_secret"],
      authorization_uri: "https://accounts.google.com/o/oauth2/auth",
      token_credential_uri: "https://accounts.google.com/o/oauth2/token",
      scope:
        "#{Google::Apis::CalendarV3::AUTH_CALENDAR_READONLY} " \
        "#{Google::Apis::PeopleV1::AUTH_USERINFO_PROFILE}",
      redirect_uri: Timeframe::Application.config.local["google_redirect_uri"],
      access_type: "offline"
    }
  end

  def healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 2.minutes
  end

  def events
    (Value.find_or_create_by(key: key).value["data"] || {})
      .values
      .map(&:values)
      .flatten
  end

  def last_fetched_at
    Value.find_or_create_by(key: key).value["last_fetched_at"]
  end

  # :nocov:
  def fetch
    begin
      refresh_token! if expires_at < Time.now
    rescue => e
      Log.create(
        globalid: key,
        event: "refresh_token_error",
        message: e.message + e.backtrace.join("\n")
      )
    end

    client = self.class.client

    begin
      client.update!(
        refresh_token: refresh_token,
        access_token: access_token,
        expires_in: 3600
      )
    rescue => e
      Log.create(
        globalid: key,
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
        globalid: key,
        event: "list_calendar_lists",
        message: e.message
      )
    end

    return unless calendars.present?

    events = {}

    Timeframe::Application.config.local["calendars"].each do |calendar_config|
      items = service.list_events(
        calendar_config["id"],
        single_events: true,
        order_by: "startTime",
        fields: "items/attendees,items/id,items/start,items/end,items/description,items/summary,items/location",
        time_min: (DateTime.now - 2.days).iso8601,
        time_max: (DateTime.now + 1.week).iso8601
      ).items

      events[calendar_config["id"]] = {}

      items.each do |event|
        event_json = event.as_json

        next if
          event_json["description"].to_s.downcase.include?("timeframe-omit") || # hide timeframe-omit
            event_json["summary"] == "." || # hide . marker
            event_json["summary"] == "Out of office" ||
            event_json["attendees"].to_a.any? { _1["self"] && _1["response_status"] == "declined" } ||
            !event_json["summary"].present?

        events[calendar_config["id"]][event.id] = CalendarEvent.new(
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
        globalid: key,
        event: "list_events_error",
        message: e.class.to_s + e.message + e.backtrace.join("\n") + calendar_config.to_json
      )
    end

    Value.upsert({key: key, value:
      {
        data: events,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }}, unique_by: :key)
  end
  # :nocov:

  private

  def key
    to_global_id.to_s
  end

  # :nocov:
  def refresh_token!
    response =
      HTTParty.post("https://accounts.google.com/o/oauth2/token",
        body: {
          grant_type: "refresh_token",
          client_id: Timeframe::Application.config.local["google_client_id"],
          client_secret: Timeframe::Application.config.local["google_client_secret"],
          refresh_token: refresh_token
        })

    response = JSON.parse(response.body)
    update(
      access_token: response["access_token"],
      expires_at: Time.now + response["expires_in"].to_i.seconds
    )
    save
  rescue => e
    Log.create(
      globalid: key,
      event: "refresh_error",
      message: e.message + response.to_s
    )
  end
  # :nocov:
end

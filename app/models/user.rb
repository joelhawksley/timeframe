# frozen_string_literal: true

class User < ApplicationRecord
  include ApplicationHelper

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :google_accounts
  has_many :google_calendars, through: :google_accounts

  def fetch
    Log.create(globalid: self.to_global_id, event: "fetch", message: "")
    WeatherService.call
    GoogleService.call
  end

  ALERT_SEVERITY_MAPPINGS = {
    "Severe" => 0,
    "Moderate" => 1
  }

  def weather
    Value.find_by_key("weather").value
  end

  def calendar_events
    Value.find_by_key("calendar_events").value
  end

  def most_important_weather_alert
    return nil unless weather.to_h.dig("nws_alerts", "features").to_a.any?

    alerts = weather["nws_alerts"]["features"]

    alerts
      .reject { |alert| alert.dig("properties", "urgency") == "Past" }
      .sort_by { |alert| ALERT_SEVERITY_MAPPINGS[alert["properties"]["severity"]] }
      .uniq { |alert| alert["properties"]["event"] }
      .reject { |alert| alert["properties"]["areaDesc"].to_s.include?("OZONE ACTION DAY") }
      .first["properties"]
  end

  # convert weather alerts to be timeline events;
  # they are timely, after all!
  def weather_calendar_events
    alert = most_important_weather_alert

    return [] unless alert

    icon =
      if String(alert["event"]).include?("Winter")
        "snowflake"
      else
        "warning"
      end

    summary =
      if String(alert["event"]).include?("Winter")
        if alert["description"].include?("Additional snow")
          alert["description"].
            gsub("\n", " ").
            split("Additional snow accumulations").
            last.
            split(".").
            first.
            strip.
            gsub(" inches", "\"")
        else
          alert["description"].
            gsub("\n", " ").
            split("accumulations between").
            last.
            split(".").
            first.
            strip.
            gsub(" and ", "-").
            gsub(" inches", "\"")
        end
      else
        alert["event"]
      end

    [{
      "start_i" => DateTime.parse(alert["effective"]).to_i,
      "end_i" => DateTime.parse(alert["expires"]).to_i,
      "calendar" => "_weather_alerts",
      "summary" => summary,
      "icon" => icon
    }]
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def calendar_events_for(beginning_i, ending_i)
    filtered_events = (weather_calendar_events + calendar_events).select do |event|
      (event["start_i"]..event["end_i"]).overlaps?(beginning_i...ending_i)
    end

    parsed_events = filtered_events.map do |event|
      event["time"] = EventTimeService.call(event["start_i"], event["end_i"], tz)
      event
    end

    parsed_events.sort_by { |event| event["start_i"] }
  end

  def render_json_payload(at = DateTime.now)
    current_time = at.utc.in_time_zone(tz)

    day_groups =
      (0..5).each_with_object([]) do |day_index, memo|
        date = Time.now.in_time_zone(tz) + day_index.day

        start_i =
          case day_index
          when 0
            # Add 180 seconds so that events ending at the top of the hour are not shown for the following half hour
            Time.now.in_time_zone(tz).utc.to_i + 180
          else
            date.beginning_of_day.utc.to_i
          end

        end_i = date.end_of_day.utc.to_i

        day_name =
          case day_index
          when 0
            "Today"
          when 1
            "Tomorrow"
          else
            date.strftime("%A")
          end

        events = calendar_events_for(start_i, end_i)
        all_day_events = events.select { |event| event["all_day"] }

        all_day_events.sort! do |x,y|
          #if this result is 1 means x should come later relative to y
	        #if this result is -1 means x should come earlier relative to y
	        #if this result is 0 means both are same so position doesn't matter
          if x["calendar"] == "Dinner" && y["calendar"] == "Us"
            1
          elsif x["summary"].starts_with?("Dinner") && y["summary"].starts_with?("Lunch")
            1
          elsif x["summary"].starts_with?("Lunch") && y["summary"].starts_with?("Breakfast")
            1
          elsif y["calendar"] == "Dinner" && x["calendar"] == "Us"
            -1
          elsif x["summary"].starts_with?("Breakfast") && y["summary"].starts_with?("Lunch")
            -1
          elsif x["summary"].starts_with?("Lunch") && y["summary"].starts_with?("Dinner")
            -1
          else
            0
          end
        end

        out = {
          day_name: day_name,
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: {
            all_day: all_day_events,
            periodic: events.reject { |event| event["all_day"] }
          },
          temperature_range: "",
          weather_icon: "",
          precip_probability: 0,
          precip_label: "",
          wind: 0
        }

        if weather&.dig("daily", "data", day_index).present?
          daily_weather = weather["daily"]["data"][day_index]

          if daily_weather["precipAccumulation"].present?
            out[:precip_label] = " #{daily_weather["precipAccumulation"].round}\""
          else
            out[:precip_label] = "#{(daily_weather["precipProbability"] * 100).to_i}%"
          end
          out[:temperature_range] = "&#8593;#{daily_weather["temperatureHigh"].round} &#8595;#{daily_weather["temperatureLow"].round}".html_safe
          out[:weather_icon] = daily_weather["icon"]
          out[:precip_probability] = daily_weather["precipProbability"]
          out[:wind] = daily_weather["windGust"].to_i
        end

        memo << out
      end

    out =
      {
        yearly_events: yearly_events,
        day_groups: day_groups,
        timestamp: current_time.in_time_zone(tz).strftime("%A at %-l:%M %p"),
        emails: emails
      }

    out[:current_temperature] = "#{weather["nearby"]["imperial"]["temp"].round}°" if weather.present?

    out
  end

  def emails
    senders =
      google_accounts.flat_map(&:emails).map do |email|
        sender = email["from"]
        return unless sender.present?

        if sender.include?(" <")
          # Clean up sender in format "Joel <joel@foo.com>" => "Joel"
          sender.split(" <").first
        elsif sender.include?("reply")
          # Clean up sender in format "noreply@foo.com" => "thriftbooks.com"
          sender.split("@").last
        else
          # Otherwise, grab the content before the @
          sender.split("@").first
        end
      end

    senders.tally
  end

  def yearly_events(at = Time.now)
    calendar_events_for(
      at.in_time_zone(tz).beginning_of_day.to_i,
      (at.in_time_zone(tz) + 1.year).end_of_day.utc.to_i
    ).select { |event| event["calendar"] == "Birthdays" }
      .first(10)
      .group_by { |e| Date.parse(e["start"]["date"]).month }
  end
end

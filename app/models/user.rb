# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :google_accounts
  has_many :google_calendars, through: :google_accounts

  def fetch
    update(error_messages: [])
    WeatherService.call(self)
    GoogleService.call(self)
  end

  def tz
    Timeframe::Application::LOCAL_TZ
  end

  ALERT_SEVERITY_MAPPINGS = {
    "warning" => 0,
    "watch" => 1,
    "advisory" => 2
  }

  def most_important_weather_alert
    return nil unless weather.to_h.key?("alerts")

    weather["alerts"]
      .uniq { |alert| alert["title"] }
      .sort_by { |alert| ALERT_SEVERITY_MAPPINGS[alert["severity"]] }
      .reject { |alert| alert["description"].to_s.include?("OZONE ACTION DAY") }
      .first
  end

  # convert weather alerts to be timeline events;
  # they are timely, after all!
  def weather_calendar_events
    alert = most_important_weather_alert

    return [] unless alert

    [{
      "start_i" => alert["time"],
      "end_i" => alert["expires"],
      "calendar" => "_weather_alerts",
      "summary" => alert["title"],
      "icon" => "warning"
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

        out = {
          day_of_week_index: date.to_date.strftime("%w").to_i,
          day_of_month: date.day,
          day_name: day_name,
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: {
            all_day: events.select { |event| event["all_day"] },
            periodic: events.reject { |event| event["all_day"] }
          },
          temperature_range: "",
          weather_icon: "",
          weather_summary: "",
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
          out[:weather_summary] = daily_weather["summary"]
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

    out[:current_temperature] = "#{weather["currently"]["temperature"].round}°" if weather.present?

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

  def alerts(include_weather_alerts = true)
    out = error_messages

    if include_weather_alerts && most_important_weather_alert
      out << most_important_weather_alert["title"]
    end

    out.uniq
  end
end

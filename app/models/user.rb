# frozen_string_literal: true

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable

  has_many :devices
  has_many :google_accounts
  has_many :google_calendars, through: :google_accounts

  def fetch
    update(error_messages: [])
    WeatherService.call(self)
    GoogleService.call(self)
  end

  def tz
    "America/Denver"
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def calendar_events_for(beginning_i, ending_i)
    filtered_events = calendar_events.select do |event|
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
      (0..3).each_with_object([]) do |day_index, memo|
        date = Time.now.in_time_zone(tz) + day_index.day

        start_i =
          case day_index
          when 0
            Time.now.in_time_zone(tz).utc.to_i
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
          }
        }

        if day_index < 7 && weather.present?
          precip_label =
            if weather["daily"]["data"][day_index]["precipAccumulation"].present?
              "#{(weather["daily"]["data"][day_index]["precipProbability"] * 100).to_i}% / #{weather["daily"]["data"][day_index]["precipAccumulation"].round(1)}\""
            else
              "#{(weather["daily"]["data"][day_index]["precipProbability"] * 100).to_i}%"
            end

          out[:temperature_range] =
            "#{weather["daily"]["data"][day_index]["temperatureHigh"].round}° / #{weather["daily"]["data"][day_index]["temperatureLow"].round}°"
          out[:weather_icon] = weather["daily"]["data"][day_index]["icon"]
          out[:weather_summary] = weather["daily"]["data"][day_index]["summary"]
          out[:precip_probability] = weather["daily"]["data"][day_index]["precipProbability"]
          out[:precip_label] = precip_label
          out[:precip_icon] = weather["daily"]["data"][day_index]["precipType"]
          out[:wind] = weather["daily"]["data"][day_index]["windGust"].to_i
          out[:wind_bearing] = weather["daily"]["data"][day_index]["windBearing"].to_i
        else
          out[:temperature_range] = ""
          out[:weather_icon] = ""
          out[:weather_summary] = ""
          out[:precip_probability] = ""
          out[:precip_label] = ""
          out[:precip_icon] = ""
          out[:wind] = ""
          out[:wind_bearing] = ""
        end

        memo << out
      end

    yearly_events =
      calendar_events_for(
        Time.now.in_time_zone(tz).beginning_of_day.to_i,
        (Time.now.in_time_zone(tz) + 1.year).end_of_day.utc.to_i
      ).select { |event| event["calendar"] == "Birthdays" }
        .first(10)
        .group_by { |e| Date.parse(e["start"]["date"]).month }

    out =
      {
        yearly_events: yearly_events,
        day_groups: day_groups,
        timestamp: current_time.in_time_zone(tz).strftime("%A at %-l:%M %p"),
        emails: google_accounts.flat_map(&:emails)
      }

    out[:current_temperature] = "#{weather["currently"]["temperature"].round}°" if weather.present?

    out
  end

  def alerts
    out = error_messages
    out.concat(weather["alerts"].map { |a| a["title"] }) if weather.key?("alerts")
    out.uniq
  end
end

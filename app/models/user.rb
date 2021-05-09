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
    CalendarService.call(self)
  end

  def tz
    "America/Denver"
  end

  def calendar_events_for(beginning_i, ending_i)
    filtered_events = calendar_events.select do |event|
      (event["start_i"]..event["end_i"]).overlaps?(beginning_i...ending_i)
    end

    parsed_events = filtered_events.map do |event|
      event["time"] = time_for_event(event, tz)
      event
    end

    parsed_events.sort_by { |event| event["start_i"] }
  end

  def render_json_payload
    current_time = DateTime.now.utc.in_time_zone(tz)

    sunrise_datetime = Time.at(weather["daily"]["data"][0]["sunriseTime"]).to_datetime.in_time_zone(tz)
    sunset_datetime = Time.at(weather["daily"]["data"][0]["sunsetTime"]).to_datetime.in_time_zone(tz)

    day_groups =
      (0..28).each_with_object([]) do |day_index, memo|
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

        if day_index < 7
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
      calendar_events_for(Time.now.in_time_zone(tz).beginning_of_day.to_i,
        (Time.now.in_time_zone(tz) + 1.year).end_of_day.utc.to_i)
        .select do |event|
        event["calendar"] == "Birthdays"
      end
        .first(10)
        .group_by do |e|
        Date.parse(e["start"]["date"]).month
      end

    hour_of_day = DateTime.now.in_time_zone(tz).hour
    hours_to_graph = 169 - hour_of_day

    hours = weather["hourly"]["data"].first(hours_to_graph).map do |e|
      {
        temperature: e["temperature"].to_f.round,
        wind_speed: e["windSpeed"].round,
        wind_bearing: e["windBearing"],
        precip_probability: (e["precipProbability"] * 100).to_i
      }
    end

    temps = hours.map { |e| e[:temperature] }

    max_temp = temps.max
    min_temp = temps.min

    scale = 180 / (max_temp - min_temp).to_f

    svg_temp_points = hours.each_with_index.map do |hour, index|
      "#{index * 14},#{190 - ((hour[:temperature] - min_temp) * scale)}"
    end.join(" ")
    svg_precip_points = hours.each_with_index.map do |hour, index|
      "#{index * 14},#{190 - (hour[:precip_probability] * 2)}"
    end.join(" ")

    {
      api_version: 3,
      yearly_events: yearly_events,
      day_groups: day_groups,
      sunset_datetime: sunset_datetime,
      time: current_time,
      timestamp: updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
      is_daytime: (current_time.strftime("%-H%M").to_i > sunrise_datetime.strftime("%-H%M").to_i) && (current_time.strftime("%-H%M").to_i < sunset_datetime.strftime("%-H%M").to_i),
      hours_to_graph: hours_to_graph,
      hour_of_day: hour_of_day,
      svg_temp_points: svg_temp_points,
      svg_precip_points: svg_precip_points,
      tz: tz,
      current_temperature: "#{weather["currently"]["temperature"].round}°"
    }
  end

  def alerts
    out = error_messages
    out.concat(weather["alerts"].map { |a| a["title"] }) if weather.key?("alerts")
    out << air if air.present?
    out.uniq
  end

  def time_for_event(event, tz)
    start = Time.at(event["start_i"]).in_time_zone(tz)
    endtime = Time.at(event["end_i"]).in_time_zone(tz)

    if start == endtime
      label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
      suffix = start.strftime("%p").gsub("AM", "a").gsub("PM", "p")

      "#{label}#{suffix}"
    else
      start_label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
      end_label = endtime.min.positive? ? endtime.strftime("%-l:%M%p") : endtime.strftime("%-l%p")
      start_suffix =
        if start.strftime("%p") == endtime.strftime("%p") && start.to_date == endtime.to_date
          ""
        else
          start.strftime("%p").gsub("AM", "a").gsub("PM", "p")
        end
      start_date = ""
      end_date = ""

      if start.to_date != endtime.to_date
        start_date = "#{start.strftime("%-m/%-e")} "
        end_date = "#{endtime.strftime("%-m/%-e")} "
      end

      "#{start_date}#{start_label}#{start_suffix} - #{end_date}#{end_label.gsub("AM", "a").gsub("PM", "p")}"
    end
  end
end

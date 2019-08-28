class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :devices

  def fetch
    update(error_messages: [])
    WeatherService.call(self)
    CalendarService.call(self)
    # AirService.call(self)
  end

  def tz
    "America/Denver"
  end

  def calendar_events_for(beginning_i, ending_i)
    calendar_events.select do |event|
      (event["start_i"]..event["end_i"]).overlaps?(beginning_i...ending_i)
    end.map do |event|
      event["time"] = time_for_event(event, tz)
      event
    end
  end

  def render_json_payload
    current_time = DateTime.now.utc.in_time_zone(tz)

    sunrise_datetime = Time.at(weather["daily"]["data"][0]["sunriseTime"]).to_datetime.in_time_zone(tz)
    sunset_datetime = Time.at(weather["daily"]["data"][0]["sunsetTime"]).to_datetime.in_time_zone(tz)

    icon_class, label =
      if (current_time.strftime("%-H%M").to_i > (sunrise_datetime.hour + sunrise_datetime.min).to_i) && (current_time.strftime("%-H%M").to_i < (sunset_datetime.hour + sunset_datetime.min).to_i)
        ["fa-moon-o", sunset_datetime.strftime("%-l:%M%P")]
      else
        ["fa-sun-o", sunrise_datetime.strftime("%-l:%M%P")]
      end

    sunrise_icon_class, sunrise_label = ["fa-sun-o", sunrise_datetime.strftime("%-l:%M%P")]

    sunset_icon_class, sunset_label = ["fa-moon-o", sunset_datetime.strftime("%-l:%M%P")]

    day_groups =
      (0..6).reduce([]) do |memo, day_index|
        start_i =
          case day_index
          when 0
            Time.now.in_time_zone(tz).utc.to_i
          else
            (Time.now.in_time_zone(tz) + day_index.day).beginning_of_day.utc.to_i
          end

        end_i =
          case day_index
          when 0
            Time.now.in_time_zone(tz).end_of_day.utc.to_i
          else
            (Time.now.in_time_zone(tz) + day_index.day).end_of_day.utc.to_i
          end

        day_name =
          case day_index
          when 0
            "Today"
          when 1
            "Tomorrow"
          else
            (Time.now.in_time_zone(tz) + day_index.day).strftime("%A")
          end

        events = calendar_events_for(start_i, end_i)

        memo << {
          day_name: day_name,
          events: {
            all_day: events.select { |event| event["all_day"] },
            periodic: events.select { |event| !event["all_day"] }
          }
        }

        memo
      end

    yearly_events =
      calendar_events_for(Time.now.in_time_zone(tz).beginning_of_day.to_i, (Time.now.in_time_zone(tz) + 1.year).end_of_day.utc.to_i).
        select { |event| event["calendar"] == "Birthdays" }.
        first(8).
        group_by { |e| Date.parse(e["start"]["date"]).month }

    {
      api_version: 3,
      yearly_events: yearly_events,
      day_groups: day_groups,
      time: current_time,
      timestamp: updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
      tz: tz,
      weather: {
        current_temperature: weather["currently"]["temperature"].round.to_s + "°",
        summary: weather["hourly"]["summary"],
        tomorrow_summary: weather["daily"]["data"][1]["summary"],
        third_day_summary: weather["daily"]["data"][2]["summary"],
        fourth_day_summary: weather["daily"]["data"][3]["summary"],
        sun_phase_icon_class: icon_class,
        sun_phase_label: label,
        sunrise_icon_class: sunrise_icon_class,
        sunrise_label: sunrise_label,
        sunset_icon_class: sunset_icon_class,
        sunset_label: sunset_label,
        today_temperature_range: "#{weather["daily"]["data"].first["temperatureHigh"].round}° / #{weather["daily"]["data"].first["temperatureLow"].round}°",
        today_icon: climacon_for_icon(weather["daily"]["data"].first["icon"]),
        tomorrow_temperature_range: "#{weather["daily"]["data"][1]["temperatureHigh"].round}° / #{weather["daily"]["data"][1]["temperatureLow"].round}°",
        tomorrow_icon: climacon_for_icon(weather["daily"]["data"][1]["icon"]),
        hours: weather["hourly"]["data"].map do |e|
          {
            time: Time.at(e["time"]).to_datetime.in_time_zone(tz).strftime("%-l:%M%P"),
            temperature: e["temperature"].to_f.round,
            icon: climacon_for_icon(e["icon"]),
            wind_speed: e["windSpeed"].round,
            wind_bearing: e["windBearing"]
          }
        end
      }
    }
  end

  def alerts
    out = error_messages
    out.concat(weather["alerts"].map { |a| a["title"] }) if weather.key?("alerts")
    out << air if air.present?
    out.uniq
  end

  def climacon_for_icon(icon)
    mappings = {
      "clear-day" => "Sun",
      "clear-night" => "Moon",
      "rain" => "Cloud-Rain",
      "snow" => "Cloud-Snow",
      "sleet" => "Cloud-Snow",
      "wind" => "Cloud-Wind",
      "fog" => "Cloud-Fog",
      "cloudy" => "Cloud",
      "partly-cloudy-day" => "Cloud-Sun",
      "partly-cloudy-night" => "Cloud-Moon"
    }

    "climacons/#{mappings[icon]}.svg"
  end

  def time_for_event(event, tz)
    start = Time.at(event["start_i"]).in_time_zone(tz)
    endtime = Time.at(event["end_i"]).in_time_zone(tz)

    start_label = start.min > 0 ? start.strftime('%-l:%M') : start.strftime('%-l')
    end_label = endtime.min > 0 ? endtime.strftime('%-l:%M%p') : endtime.strftime('%-l%p')
    start_suffix =
      if start.strftime('%p') == endtime.strftime('%p') && start.to_date == endtime.to_date
        ''
      else
        start.strftime('%p').gsub("AM", "a").gsub("PM", "p")
      end
    start_date = ""
    end_date = ""

    if start.to_date != endtime.to_date
      start_date = "#{start.strftime("%-m/%e")} "
      end_date = "#{endtime.strftime("%-m/%e")} "
    end

    "#{start_date}#{start_label}#{start_suffix} - #{end_date}#{end_label.gsub("AM", "a").gsub("PM", "p")}"
  end
end

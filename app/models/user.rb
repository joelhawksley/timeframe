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
      event["start_time"] = start_time_for_event(event, tz)
      event
    end
  end

  def render_json_payload
    current_time = DateTime.now.utc.in_time_zone(tz)

    sunrise_datetime = Time.at(weather["daily"]["data"][0]["sunriseTime"]).to_datetime.in_time_zone(tz)
    sunset_datetime = Time.at(weather["daily"]["data"][0]["sunsetTime"]).to_datetime.in_time_zone(tz)

    icon_class, label =
      if (current_time.strftime("%-H%M").to_i > sunrise_datetime.strftime("%-H%M").to_i) && (current_time.strftime("%-H%M").to_i < sunset_datetime.strftime("%-H%M").to_i)
        ["fa-moon-o", sunset_datetime.strftime("%-l:%M%P")]
      else
        ["fa-sun-o", sunrise_datetime.strftime("%-l:%M%P")]
      end

    day_groups =
      (0..28).reduce([]) do |memo, day_index|
        date = Time.now.in_time_zone(tz) + day_index.day

        start_i =
          case day_index
          when 0
            Time.now.in_time_zone(tz).utc.to_i
          else
            date.beginning_of_day.utc.to_i
          end

        end_i =
          case day_index
          when 0
            date.end_of_day.utc.to_i
          else
            date.end_of_day.utc.to_i
          end

        day_name =
          case day_index
          when 0
            "Today"
          else
            date.strftime("%A")
          end

        events = calendar_events_for(start_i, end_i)

        out = {
          day_of_week_index: date.to_date.strftime("%w").to_i,
          day_of_month: date.day,
          day_name: day_name,
          events: {
            all_day: events.select { |event| event["all_day"] },
            periodic: events.select { |event| !event["all_day"] }
          }
        }

        if day_index < 7
          out[:temperature_range] = "#{weather["daily"]["data"][day_index]["temperatureHigh"].round}° / #{weather["daily"]["data"][day_index]["temperatureLow"].round}°"
          out[:weather_icon] = weather["daily"]["data"][day_index]["icon"]
          out[:weather_summary] = weather["daily"]["data"][day_index]["summary"]
          out[:precip_probability] = weather["daily"]["data"][day_index]["precipProbability"]
          out[:precip_icon] = weather["daily"]["data"][day_index]["precipType"]
        else
          out[:temperature_range] = ""
          out[:weather_icon] = ""
          out[:weather_summary] = ""
          out[:precip_probability] = ""
          out[:precip_icon] = ""
        end

        memo << out

        memo
      end

    yearly_events =
      calendar_events_for(Time.now.in_time_zone(tz).beginning_of_day.to_i, (Time.now.in_time_zone(tz) + 1.year).end_of_day.utc.to_i).
        select { |event| event["calendar"] == "Birthdays" }.
        first(16).
        group_by { |e| Date.parse(e["start"]["date"]).month }

    precip_label =
      if weather["daily"]["data"][0]["precipAccumulation"].present?
        "#{(weather["daily"]["data"][0]["precipProbability"] * 100).to_i}% / #{weather["daily"]["data"][0]["precipAccumulation"].round(1)}\""
      else
        "#{(weather["daily"]["data"][0]["precipProbability"] * 100).to_i}%"
      end

    hour_of_day = DateTime.now.in_time_zone(tz).hour
    hours_to_graph = 169 - hour_of_day

    hours = weather["hourly"]["data"].first(hours_to_graph).map do |e|
      {
        temperature: e["temperature"].to_f.round,
        wind_speed: e["windSpeed"].round,
        wind_bearing: e["windBearing"],
        precip_probability: (e["precipProbability"] * 100).to_i,
      }
    end

    temps = hours.map { |e| e[:temperature] }

    max_temp = temps.max
    min_temp = temps.min

    scale = 180 / (max_temp - min_temp).to_f

    svg_temp_points = hours.each_with_index.map { |hour, index| "#{index * 14},#{190 - ((hour[:temperature] - min_temp) * scale)}" }.join(" ")
    svg_precip_points = hours.each_with_index.map { |hour, index| "#{index * 14},#{190 - (hour[:precip_probability] * 2)}" }.join(" ")

    {
      api_version: 3,
      yearly_events: yearly_events,
      day_groups: day_groups,
      sun_phase_icon_class: icon_class,
      sun_phase_label: label,
      sunset_datetime: sunset_datetime,
      time: current_time,
      timestamp: updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
      is_daytime: (current_time.strftime("%-H%M").to_i > sunrise_datetime.strftime("%-H%M").to_i) && (current_time.strftime("%-H%M").to_i < sunset_datetime.strftime("%-H%M").to_i),
      hours_to_graph: hours_to_graph,
      hour_of_day: hour_of_day,
      svg_temp_points: svg_temp_points,
      svg_precip_points: svg_precip_points,
      tz: tz,
      weather: {
        current_temperature: weather["currently"]["temperature"].round.to_s + "°",
        precip_probability: weather["daily"]["data"][0]["precipProbability"],
        precip_label: precip_label,
        precip_type: weather["daily"]["data"][0]["precipType"],
        humidity: "#{(weather["daily"]["data"][0]["humidity"] * 100).to_i}%",
        wind: weather["daily"]["data"][0]["windGust"].to_i,
        wind_bearing: weather["daily"]["data"][0]["windBearing"].to_i,
        visibility: "#{weather["daily"]["data"][0]["visibility"].to_i} mi",
      }
    }
  end

  def alerts
    out = error_messages
    out.concat(weather["alerts"].map { |a| a["title"] }) if weather.key?("alerts")
    out << air if air.present?
    out.uniq
  end

  def start_time_for_event(event, tz)
    start = Time.at(event["start_i"]).in_time_zone(tz)

    start_label = start.min > 0 ? start.strftime('%-l:%M') : start.strftime('%-l')
    start_suffix = start.strftime('%p').gsub("AM", "a").gsub("PM", "p")

    "#{start_label}#{start_suffix}"
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

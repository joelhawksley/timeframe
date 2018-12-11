class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_many :devices

  def fetch
    update(error_messages: [])
    WeatherService.call(self)
    CalendarService.call(self)
    AirService.call(self)
    SkiService.call(self)
  end

  def calendar_events_for(beginning_i, ending_i)
    calendar_events.select do |event|
      (event["start_i"]..event["end_i"]).overlaps?(beginning_i...ending_i)
    end
  end

  def render_json_payload
    tz = "America/Denver"
    time = DateTime.now.utc.in_time_zone(tz)

    sun_phase = weather["sun_phase"]
    icon_class, label =
      if (time.strftime("%-H%M").to_i > (sun_phase["sunrise"]["hour"] + sun_phase["sunrise"]["minute"]).to_i) && (time.strftime("%-H%M").to_i < (sun_phase["sunset"]["hour"] + sun_phase["sunset"]["minute"]).to_i)
        ["fa-moon-o", "#{sun_phase["sunset"]["hour"].to_i - 12}:#{sun_phase["sunset"]["minute"]}pm"]
      else
        ["fa-sun-o", "#{sun_phase["sunrise"]["hour"]}:#{sun_phase["sunrise"]["minute"]}am"]
      end

    sunrise_icon_class, sunrise_label = ["fa-sun-o", "#{sun_phase["sunrise"]["hour"]}:#{sun_phase["sunrise"]["minute"]}am"]

    sunset_icon_class, sunset_label = ["fa-moon-o", "#{sun_phase["sunset"]["hour"].to_i - 12}:#{sun_phase["sunset"]["minute"]}pm"]

    today_events =
      calendar_events_for(Time.now.in_time_zone(tz).to_i, Time.now.in_time_zone(tz).end_of_day.utc.to_i).map do |event|
        event["time"] = time_for_event(event, tz)
        event
      end

    tomorrow_events =
      calendar_events_for(Time.now.in_time_zone(tz).tomorrow.beginning_of_day.to_i, Time.now.in_time_zone(tz).tomorrow.end_of_day.utc.to_i).map do |event|
        event["time"] = time_for_event(event, tz)
        event
      end

    {
      api_version: 3,
      ski_reports: ski_reports,
      today_events: {
        all_day: today_events.select { |event| event["all_day"] },
        periodic: today_events.select { |event| !event["all_day"] }
      },
      tomorrow_events: {
        all_day: tomorrow_events.select { |event| event["all_day"] },
        periodic: tomorrow_events.select { |event| !event["all_day"] }
      },
      time: time,
      timestamp: updated_at.in_time_zone(tz).strftime("%A at %l:%M %p"),
      tz: tz,
      weather: {
        current_temperature: weather["current_observation"]["temp_f"].round.to_s + "°",
        summary: weather["forecast"]["txt_forecast"]["forecastday"].first["fcttext"],
        sun_phase_icon_class: icon_class,
        sun_phase_label: label,
        sunrise_icon_class: sunrise_icon_class,
        sunrise_label: sunrise_label,
        sunset_icon_class: sunset_icon_class,
        sunset_label: sunset_label,
        today_temperature_range: "#{weather["forecast"]["simpleforecast"]["forecastday"].first["high"]["fahrenheit"]}° / #{weather["forecast"]["simpleforecast"]["forecastday"].first["low"]["fahrenheit"]}°",
        today_icon: weather["forecast"]["simpleforecast"]["forecastday"][1]["icon"],
        tomorrow_temperature_range: "#{weather["forecast"]["simpleforecast"]["forecastday"][1]["high"]["fahrenheit"]}° / #{weather["forecast"]["simpleforecast"]["forecastday"][1]["low"]["fahrenheit"]}°",
        tomorrow_icon: weather["forecast"]["simpleforecast"]["forecastday"][1]["icon"]
      }
    }
  end

  def alerts
    out = error_messages
    out.concat(weather["alerts"].map { |a| a["description"] })
    out << air if air.present?
    out.uniq
  end

  def time_for_event(event, tz)
    start = Time.at(event["start_i"]).in_time_zone(tz)
    endtime = Time.at(event["end_i"]).in_time_zone(tz)

    start_label = start.min > 0 ? start.strftime('%-l:%M') : start.strftime('%-l')
    end_label = endtime.min > 0 ? endtime.strftime('%-l:%M%P') : endtime.strftime('%-l%P')
    start_suffix =
      if start.strftime('%P') == endtime.strftime('%P') && start.to_date == endtime.to_date
        ''
      else
        start.strftime('%P')
      end
    start_date = ""
    end_date = ""

    if start.to_date != endtime.to_date
      start_date = "#{start.strftime("%-m/%e")} "
      end_date = "#{endtime.strftime("%-m/%e")} "
    end

    "#{start_date}#{start_label}#{start_suffix} - #{end_date}#{end_label}"
  end
end

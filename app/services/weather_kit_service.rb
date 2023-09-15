class WeatherKitService
  def self.weather
    Current.weatherkit ||=
      Value.find_or_create_by(key: "weatherkit").value["data"] || {}
  end

  def self.last_fetched_at
    Current.weatherkit_fetched_at ||=
      Value.find_or_create_by(key: "weatherkit").value["last_fetched_at"]
  end

  def self.current_temperature
    raw_temp = weather.dig("currentWeather", "temperature")

    return nil unless raw_temp

    "#{celsius_fahrenheit(weather.dig("currentWeather", "temperature"))}°"
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 2.minutes
  end

  def self.fetch
    client = Tenkit::Client.new
    local_config = Timeframe::Application.config.local
    Value.find_or_create_by(key: "weatherkit").update(value:
      {
        data:
          client.weather(
            local_config["latitude"],
            local_config["longitude"],
            data_sets: [
              :current_weather,
              :forecast_next_hour,
              :forecast_daily,
              :forecast_hourly,
              :weather_alerts
            ]
          ).raw,
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    )
  rescue => e
    Log.create(
      globalid: "WeatherKitService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def self.hourly_calendar_events
    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

    hours_forecast = weather.dig("forecastHourly", "hours")

    return [] unless hours_forecast.present?

    [today, today.tomorrow, today + 2.day, today + 3.day].flat_map do |twz|
      [
        (twz.noon - 4.hours),
        twz.noon,
        (twz.noon + 4.hours),
        (twz.noon + 8.hours)
      ].map do |hour|
        weather_hour =
          hours_forecast.find do
            DateTime.parse(_1["forecastStart"]) == hour
          end

        next if !weather_hour.present?

        CalendarEvent.new(
          id: "_weather_hour_#{hour.to_i}",
          starts_at: hour,
          ends_at: hour,
          icon: icon_for(weather_hour["conditionCode"]),
          summary: "#{celsius_fahrenheit(weather_hour['temperature'])}°".html_safe
        )
      end.compact
    end
  end

  def self.precip_calendar_events
    events = []

    hours_forecast = weather.dig("forecastHourly", "hours")

    return events unless hours_forecast.present?

    hours = weather["forecastHourly"]["hours"]

    hours.each_with_index do |hour, index|
      existing_event =
        events.find do
          _1[:end_i] == DateTime.parse(hour["forecastStart"]).to_i &&
          _1[:precipitation_type] == hour["precipitationType"]
        end

      if existing_event
        existing_event[:end_i] += 3600
      else
        events <<
          {
            start_i: DateTime.parse(hour["forecastStart"]).to_i,
            end_i: (DateTime.parse(hour["forecastStart"]) + 1.hour).to_i,
            precipitation_type: hour["precipitationType"]
          }
      end
    end

    events.select { _1[:precipitation_type] != "clear" }.map do
      CalendarEvent.new(
        id: "#{_1[:start_i]}_window",
        starts_at: _1[:start_i],
        ends_at:_1[:end_i],
        icon: "raindrops",
        summary: _1[:precipitation_type].capitalize
      )
    end
  end

  def self.icon_for(condition_code)
    icon_mappings = {
      "Cloudy" => "clouds",
      "MostlyCloudy" => "clouds",
      "PartlyCloudy" => "clouds-sun",
      "MostlyClear" => "cloud-sun",
      "Clear" => "sun",
      "Windy" => "wind",
      "Drizzle" => "raindrops",
      "Rain" => "raindrops"
    }

    icon_mappings[condition_code] || "question"
  end

  def self.daily_calendar_events
    return [] unless days = weather.dig("forecastDaily", "days")

    days.map do |day|
      CalendarEvent.new(
        id: "_weather_day_#{day['forecastStart']}",
        starts_at: DateTime.parse(day['forecastStart']).to_i,
        ends_at:  DateTime.parse(day['forecastEnd']).to_i,
        icon: icon_for(day["conditionCode"]),
        summary: "#{celsius_fahrenheit(day['temperatureMax'])}° / #{celsius_fahrenheit(day['temperatureMin'])}°".html_safe
      )
    end
  end

  def self.celsius_fahrenheit(c)
    (c * 9 / 5 + 32).round
  end
end
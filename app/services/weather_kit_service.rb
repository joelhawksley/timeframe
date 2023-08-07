class WeatherKitService
  def self.weather
    Value.find_or_create_by(key: "weatherkit").value["data"]
  end

  def self.temperature_range_for(date)
    forecast = weather["forecastDaily"]["days"].find{ _1["forecastStart"].to_date == date }

    "&#8593;#{celsius_fahrenheit(forecast["temperatureMax"])} &#8595;#{celsius_fahrenheit(forecast["temperatureMin"])}".html_safe
  end

  def self.current_temperature
    celsius_fahrenheit(weather["currentWeather"]["temperature"])
  end

  def self.healthy?
    DateTime.parse(
      Value.find_or_create_by(key: "weatherkit").value["last_fetched_at"]
    ) < DateTime.now - 1.hour
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

  def self.calendar_events
    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

    [today, today.tomorrow, today + 2.day, today + 3.day].flat_map do |twz|
      [
        (twz.noon - 4.hours),
        twz.noon,
        (twz.noon + 4.hours),
        (twz.noon + 8.hours)
      ].map do |hour|
        weather_hour =
          weather["forecastHourly"]["hours"].find do
            DateTime.parse(_1["forecastStart"]) == hour
          end

        next if !weather_hour.present?

        CalendarEvent.new(
          id: "_weather_hour_#{hour.to_i}",
          start_i: hour.to_i,
          end_i: hour.to_i,
          calendar: '_weather_hours',
          icon: icon_for(weather_hour['conditionCode']),
          summary: "#{celsius_fahrenheit(weather_hour['temperature'])}°".html_safe
        )
      end.compact
    end
  end

  def self.icon_for(condition_code)
    mappings = {
      "MostlyCloudy" => "clouds",
      "PartlyCloudy" => "clouds-sun",
      "MostlyClear" => "cloud-sun",
      "Clear" => "sun",
      "/day/wind_bkn" => "wind",
      "/day/wind_few" => "wind",
      "/day/wind_sct" => "wind",
      "/day/rain" => "raindrops",
      "/day/tsra_hi" => "raindrops",
      "/day/tsra_sct" => "raindrops",
      "/day/tsra" => "raindrops",
      "/day/rain_showers" => "raindrops",
      "/day/snow" => "snowflake",
      "/day/blizzard" => "snowflake",
      "/day/cold" => "hat-winter",
      "/day/fog" => "cloud-fog",
      "/day/skc" => "sun",
      "/day/smoke" => "smoke",
      "/day/hot" => "temperature-high",
      "/night/ovc" => "clouds",
      "/night/bkn" => "clouds-moon",
      "/night/sct" => "cloud-moon",
      "/night/few" => "moon",
      "/night/skc" => "moon",
      "/night/wind_bkn" => "wind",
      "/night/wind_few" => "wind",
      "/night/wind_sct" => "wind",
      "/night/rain" => "raindrops",
      "/night/tsra_hi" => "raindrops",
      "/night/tsra_sct" => "raindrops",
      "/night/tsra" => "raindrops",
      "/night/rain_showers" => "raindrops",
      "/night/snow" => "snowflake",
      "/night/blizzard" => "snowflake",
      "/night/cold" => "hat-winter",
      "/night/fog" => "cloud-fog",
      "/night/smoke" => "smoke",
      "/night/hot" => "temperature-high"
    }

    mappings[condition_code] || "question"
  end

  def self.precip_calendar_events
    events = []

    periods.each do |hour|
      next unless hour['icon'].split(',').length == 2

      summary, icon =
        case hour['icon'].split(',').first
        when 'snow', 'blizzard'
          %w[Snow snowflake]
        when 'rain', 'rain_showers', 'tsra', 'tsra_sct', 'tsra_hi'
          %w[Rain raindrops]
        when 'smoke'
          %w[Smoke smoke]
        end

      next unless summary

      if (existing_index = events.find_index { _1['summary'] == summary && _1['end_i'] == hour['start_i'] })
        events[existing_index]['end_i'] = hour['end_i']
      else
        events <<
          CalendarEvent.new(
            id: "#{hour['start_i']}_window",
            start_i: hour['start_i'],
            end_i: hour['end_i'],
            calendar: '_weather_alerts',
            icon: icon,
            summary: summary
          )
      end
    end

    events
  end

  def self.celsius_fahrenheit(c)
    (c * 9 / 5 + 32).round
  end
end
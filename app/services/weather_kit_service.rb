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

  def self.celsius_fahrenheit(c)
    (c * 9 / 5 + 32).round
  end
end
class WeatherKitService
  def self.weather
    Value.find_or_create_by(key: "weatherkit").value["data"]
  end

  def self.current_temperature
    celsius_fahrenheit(weather["current_weather"]["temperature"]).round
  end

  def self.fetch
    client = Tenkit::Client.new
    local_config = Timeframe::Application.config.local
    Value.find_or_create_by(key: "weatherkit").update(value:
      {
        data:
          JSON.parse(client.weather(
            local_config["latitude"],
            local_config["longitude"],
            data_sets: [
              :current_weather,
              :forecast_daily,
              :forecast_hourly,
              :weather_alerts
            ]
          ).weather.to_json),
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
    c * 9 / 5 + 32
  end
end
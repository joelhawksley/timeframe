# frozen_string_literal: true

class PirateWeatherService
  def self.current_temperature
    weather["currently"]["temperature"]
  end

  def self.temperature_range_for(date)
    forecast = weather["daily"]["data"].find { Time.at(_1["time"]).to_date == date }

    "&#8593;#{forecast["temperatureHigh"].round} &#8595;#{forecast["temperatureLow"].round}".html_safe
  end

  def self.fetch
    Value.find_or_create_by(key: "pirate_weather").update(value:
      HTTParty.get(
        "https://api.pirateweather.net/forecast/#{Timeframe::Application.config.local["pirate_weather_api_key"]}/#{ENV["LAT_LONG"]}"
      )
    )

    Log.create(
      globalid: "PirateWeatherService",
      event: "call_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: "PirateWeatherService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def self.healthy?(log = Log.where(globalid: 'PirateWeatherService', event: 'call_success').last)
    return false unless log

    log.created_at > DateTime.now - 1.hour
  end

  def self.weather
    Value.find_or_create_by(key: "pirate_weather").value
  end
end

# frozen_string_literal: true

class WeatherService
  def self.call
    result = {}

    result["wunderground_forecast"] = HTTParty.get(
      "https://api.weather.com/v3/wx/forecast/daily/5day?geocode=#{ENV["LAT_LONG"]}" \
      "&format=json&units=e&language=en-US&apiKey=#{ENV["WUNDERGROUND_TOKEN"]}"
    )

    Value.find_or_create_by(key: "weather").update(value: result)

    Log.create(
      globalid: "WeatherService",
      event: "call_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: "WeatherService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def self.healthy?(log = Log.where(globalid: 'WeatherService', event: 'call_success').last)
    return false unless log

    log.created_at > DateTime.now - 1.hour
  end

  def self.weather
    @weather ||= Value.weather
  end
end

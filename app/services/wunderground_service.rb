# frozen_string_literal: true

class WundergroundService
  def self.fetch
    Value.find_or_create_by(key: "wunderground").update(value:
      HTTParty.get(
        "https://api.weather.com/v3/wx/forecast/daily/5day?geocode=#{ENV["LAT_LONG"]}" \
        "&format=json&units=e&language=en-US&apiKey=#{ENV["WUNDERGROUND_TOKEN"]}"
      )
    )

    Log.create(
      globalid: "WundergroundService",
      event: "call_success",
      message: ""
    )
  rescue => e
    Log.create(
      globalid: "WundergroundService",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def self.healthy?(log = Log.where(globalid: 'WundergroundService', event: 'call_success').last)
    return false unless log

    log.created_at > DateTime.now - 1.hour
  end

  def self.weather
    @weather ||= Value.weather
  end
end

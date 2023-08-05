# frozen_string_literal: true

class WeatherService
  def self.call
    result = {}

    result["wunderground_forecast"] = HTTParty.get(
      "https://api.weather.com/v3/wx/forecast/daily/5day?geocode=#{ENV["LAT_LONG"]}" \
      "&format=json&units=e&language=en-US&apiKey=#{ENV["WUNDERGROUND_TOKEN"]}"
    )

    result["weatherflow_forecast"] = HTTParty.get(
      "https://swd.weatherflow.com/swd/rest/better_forecast?station_id=#{ENV['WEATHERFLOW_STATION_ID']}" \
      "&units_temp=f&units_wind=mph&units_pressure=mb&units_precip=in&units_distance=mi" \
      "&token=#{ENV["WEATHERFLOW_TOKEN"]}"
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

  def self.calendar_events
    out = []

    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

    [today, today.tomorrow, today + 2.day, today + 3.day].each do |twz|
      noon_i = twz.noon.to_i
      weather_hour = HourlyWeatherService.for(noon_i)

      if weather_hour.present?
        out <<
          CalendarEvent.new(
            id: noon_i,
            start_i: noon_i,
            end_i: noon_i,
            calendar: '_weather_alerts',
            icon: weather_hour['icon_class'],
            summary: "#{weather_hour['temperature'].round}°".html_safe
          )
      end

      p_i = (twz.noon + 4.hours).to_i
      weather_hour = HourlyWeatherService.for(p_i)

      if weather_hour.present?
        out <<
          CalendarEvent.new(
            id: p_i,
            start_i: p_i,
            end_i: p_i,
            calendar: '_weather_alerts',
            icon: weather_hour['icon_class'],
            summary: "#{weather_hour['temperature'].round}°".html_safe
          )
      end
    end

    weather.dig('wunderground_forecast', 'sunsetTimeLocal').to_a.each do |sunset_time|
      sunset_i = DateTime.parse(sunset_time).to_i
      weather_hour = HourlyWeatherService.for(sunset_i)

      next unless weather_hour

      out <<
        CalendarEvent.new(
          id: sunset_i,
          start_i: sunset_i,
          end_i: sunset_i,
          calendar: '_weather_alerts',
          icon: weather_hour['icon_class'],
          summary: "#{weather_hour['temperature'].round}°".html_safe
        )
    end

    weather.dig('wunderground_forecast', 'sunriseTimeLocal').to_a.each do |sunrise_time|
      sunrise_i = DateTime.parse(sunrise_time).to_i
      weather_hour = HourlyWeatherService.for(sunrise_i)

      next unless weather_hour

      out <<
        CalendarEvent.new(
          id: sunrise_i,
          start_i: sunrise_i,
          end_i: sunrise_i,
          calendar: '_weather_alerts',
          icon: weather_hour['icon_class'],
          summary: "#{weather_hour['temperature'].round}°".html_safe
        )
    end

    out
  end

  def self.weather
    @weather ||= Value.weather
  end
end

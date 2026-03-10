class WeatherKitApi < Api
  def initialize(home_assistant_config_api: HomeAssistantConfigApi.new, config: Timeframe::Application.config.local)
    @home_assistant_config_api = home_assistant_config_api
    @config = config
  end

  def fetch
    client = Tenkit::Client.new
    hash = client.weather(
      @home_assistant_config_api.latitude,
      @home_assistant_config_api.longitude,
      data_sets: [
        :current_weather,
        :forecast_next_hour,
        :forecast_daily,
        :forecast_hourly,
        :weather_alerts
      ]
    ).raw

    # Do not update unless response is well formed
    return unless hash.key?("currentWeather")

    save_response(hash)
  end

  def current_temperature
    raw_temp = data.dig(:currentWeather, :temperature)

    return nil unless raw_temp

    "#{format_temperature(data.dig(:currentWeather, :temperature))}°"
  end

  def hourly_calendar_events
    today = Date.today.in_time_zone(HomeAssistantConfigApi.new.time_zone)

    hours_forecast = data.dig(:forecastHourly, :hours)

    return [] unless hours_forecast.present?

    [today, today.tomorrow, today + 2.day, today + 3.day, today + 4.day, today + 5.day].flat_map do |twz|
      [
        (twz.noon - 4.hours),
        twz.noon,
        (twz.noon + 4.hours),
        (twz.noon + 8.hours)
      ].map do |hour|
        hour_str = hour.utc.iso8601
        weather_hour = hours_forecast.find { it[:forecastStart] == hour_str }

        next if !weather_hour.present?

        CalendarEvent.new(
          id: "_weather_hour_#{hour.to_i}",
          starts_at: hour,
          ends_at: hour,
          icon: icon_for(weather_hour[:conditionCode]),
          summary: "#{format_temperature(weather_hour[:temperature])}°".html_safe
        )
      end.compact
    end
  end

  def wind_calendar_events
    events = []

    hours_forecast = data.dig(:forecastHourly, :hours)

    return events unless hours_forecast.present?

    hours = data[:forecastHourly][:hours]

    metric_wind = @config["speed_format"] == "metric"
    wind_threshold = metric_wind ? 32.0 : 20.0
    wind_unit = metric_wind ? "km/h" : "mph"

    hours.each do |hour|
      wind_speed = hour[:windGust].to_f
      wind_speed *= 0.621371 unless metric_wind
      next if wind_speed < wind_threshold

      hour_i = DateTime.parse(hour[:forecastStart]).to_i

      next if hour_i < Time.now.to_i

      existing_event =
        events.find { it[:end_i] == hour_i }

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:wind_max] = [existing_event[:wind_max], wind_speed].max
        existing_event[:wind_directions] << hour[:windDirection]
      else
        events <<
          {
            start_i: hour_i,
            end_i: (DateTime.parse(hour[:forecastStart]) + 1.hour).to_i,
            wind_max: wind_speed,
            wind_directions: [hour[:windDirection]]
          }
      end
    end

    events.map do
      # Convert angles to unit vectors, average, then convert back to angle
      radians = it[:wind_directions].map { |d| d * Math::PI / 180 }
      avg_x = radians.sum { |r| Math.cos(r) } / radians.size
      avg_y = radians.sum { |r| Math.sin(r) } / radians.size
      avg_wind_direction = (Math.atan2(avg_y, avg_x) * 180 / Math::PI).round

      CalendarEvent.new(
        id: "#{it[:start_i]}_wind",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: "arrow-up",
        icon_rotation: avg_wind_direction,
        summary: "Gusts up to #{it[:wind_max].round}#{wind_unit}"
      )
    end
  end

  def precip_calendar_events
    events = []

    hours_forecast = data.dig(:forecastHourly, :hours)

    return events unless hours_forecast.present?

    hours = data[:forecastHourly][:hours]

    hours.each_with_index do |hour, index|
      hour_i = DateTime.parse(hour[:forecastStart]).to_i

      next if hour_i < Time.now.to_i

      existing_event =
        events.find { it[:end_i] == hour_i && it[:precipitation_type] == hour[:precipitationType] }

      if existing_event
        existing_event[:end_i] += 3600
      else
        events <<
          {
            start_i: hour_i,
            end_i: (DateTime.parse(hour[:forecastStart]) + 1.hour).to_i,
            precipitation_type: hour[:precipitationType]
          }
      end
    end

    events.select { it[:precipitation_type] != "clear" }.map do
      icon =
        case it[:precipitation_type]
        when "snow", "mixed", "wintrymix"
          "snowflake"
        when "rain"
          "weather-rainy"
        end

      CalendarEvent.new(
        id: "#{it[:start_i]}_window",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: icon,
        summary: it[:precipitation_type].capitalize
      )
    end
  end

  def weather_alert_calendar_events
    alerts = data.dig(:weatherAlerts, :alerts)

    return [] unless alerts.present?

    alerts.map do |alert|
      next if ["Air Quality Alert", "Heat Advisory"].any? { alert[:description].include?(it) }

      CalendarEvent.new(
        id: alert["id"],
        starts_at: alert[:effectiveTime],
        ends_at: alert[:expireTime],
        icon: "alert",
        summary: alert[:description]
      )
    end.compact
  end

  def icon_for(condition_code)
    icon_mappings = {
      "Thunderstorms" => "weather-lightning",
      "Cloudy" => "cloud",
      "MostlyCloudy" => "cloud",
      "PartlyCloudy" => "weather-partly-cloudy",
      "MostlyClear" => "weather-partly-cloudy",
      "Clear" => "weather-sunny",
      "Windy" => "weather-windy",
      "Drizzle" => "weather-rainy",
      "Rain" => "weather-rainy",
      "HeavyRain" => "weather-rainy",
      "Haze" => "weather-fog",
      "Snow" => "snowflake",
      "HeavySnow" => "snowflake",
      "Flurries" => "snowflake",
      "WintryMix" => "snowflake",
      "Mixed" => "snowflake"
    }

    if icon_mappings[condition_code]
      icon_mappings[condition_code]
    else
      Rails.logger.info("Unknown condition code: #{condition_code}")

      "help-circle"
    end
  end

  def daily_calendar_events
    return [] unless (days = data.dig(:forecastDaily, :days))

    days.map do |day|
      summary_suffix =
        if day.dig(:precipitationType) == "snow"
          format_rainfall(day[:snowfallAmount]) if day.dig(:snowfallAmount) > 0.05
        elsif day.dig(:precipitationAmount).to_f >= 2.54
          format_rainfall(day[:precipitationAmount])
        end

      CalendarEvent.new(
        id: "_weather_day_#{day[:forecastStart]}",
        starts_at: DateTime.parse(day[:forecastStart]).to_i,
        ends_at: DateTime.parse(day[:forecastEnd]).to_i,
        icon: icon_for(day[:conditionCode]),
        summary: "#{format_temperature(day[:temperatureMax])}° / #{format_temperature(day[:temperatureMin])}°#{summary_suffix}".html_safe
      )
    end
  end

  def format_temperature(c)
    if @config["air_temp_format"] == "metric"
      c.round
    else
      (c * 9 / 5 + 32).round
    end
  end

  def format_rainfall(mm)
    if @config["rainfall_format"] == "metric"
      if mm >= 10
        " / #{(mm / 10.0).round(1)}cm"
      else
        " / #{mm.round(1)}mm"
      end
    else
      " / #{(mm * 0.0393701).round(1)}\""
    end
  end
end

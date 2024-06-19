class WeatherKitApi < Api
  def fetch
    client = Tenkit::Client.new
    local_config = Timeframe::Application.config.local
    hash = client.weather(
      local_config["latitude"],
      local_config["longitude"],
      data_sets: [
        :current_weather,
        :forecast_next_hour,
        :forecast_daily,
        :forecast_hourly,
        :weather_alerts
      ]
    ).raw

    # :nocov:
    # Do not update unless response is well formed
    return unless hash.key?("currentWeather")

    save_response(hash)
    # :nocov:
  rescue => e
    Log.create(
      globalid: "WeatherKit",
      event: "call_error",
      message: e.message + e.backtrace.join("\n")
    )
  end

  def current_temperature
    raw_temp = data.dig(:currentWeather, :temperature)

    return nil unless raw_temp

    "#{celsius_fahrenheit(data.dig(:currentWeather, :temperature))}°"
  end

  def hourly_calendar_events
    today = Date.today.in_time_zone(Timeframe::Application.config.local["timezone"])

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
        weather_hour = hours_forecast.find { _1[:forecastStart] == hour_str }

        next if !weather_hour.present?

        wind_suffix = if weather_hour[:windGust].to_f * 0.621371 > 20
          " / #{(weather_hour[:windGust] * 0.621371).round}mph"
        end

        CalendarEvent.new(
          id: "_weather_hour_#{hour.to_i}",
          starts_at: hour,
          ends_at: hour,
          icon: icon_for(weather_hour[:conditionCode]),
          summary: "#{celsius_fahrenheit(weather_hour[:temperature])}°#{wind_suffix}".html_safe
        )
      end.compact
    end
  end

  def precip_calendar_events
    events = []

    hours_forecast = data.dig(:forecastHourly, :hours)

    return events unless hours_forecast.present?

    hours = data[:forecastHourly][:hours]

    hours.each_with_index do |hour, index|
      hour_i = DateTime.parse(hour[:forecastStart]).to_i

      existing_event =
        events.find { _1[:end_i] == hour_i && _1[:precipitation_type] == hour[:precipitationType] }

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

    events.select { _1[:precipitation_type] != "clear" }.map do
      icon =
        case _1[:precipitation_type]
        when "snow"
          "snowflake"
        when "rain"
          "raindrops"
        end

      CalendarEvent.new(
        id: "#{_1[:start_i]}_window",
        starts_at: _1[:start_i],
        ends_at: _1[:end_i],
        icon: icon,
        summary: _1[:precipitation_type].capitalize
      )
    end
  end

  def weather_alert_calendar_events
    alerts = data.dig(:weatherAlerts, :alerts)

    return [] unless alerts.present?

    alerts.map do |alert|
      next if alert[:description].include?("Red Flag Warning") || alert[:description].include?("Air Quality Alert")

      CalendarEvent.new(
        id: alert["id"],
        starts_at: alert[:effectiveTime],
        ends_at: alert[:expireTime],
        icon: "triangle-exclamation",
        summary: alert[:description]
      )
    end.compact
  end

  def icon_for(condition_code)
    icon_mappings = {
      "Thunderstorms" => "cloud-bolt",
      "Cloudy" => "clouds",
      "MostlyCloudy" => "clouds",
      "PartlyCloudy" => "clouds-sun",
      "MostlyClear" => "cloud-sun",
      "Clear" => "sun",
      "Windy" => "wind",
      "Drizzle" => "raindrops",
      "Rain" => "raindrops",
      "HeavyRain" => "raindrops",
      "Haze" => "sun-haze",
      "Snow" => "snowflake",
      "HeavySnow" => "snowflakes",
      "Flurries" => "snowflake"
    }

    if icon_mappings[condition_code]
      icon_mappings[condition_code]
    else
      Log.create(
        globalid: "WeatherKit",
        event: "icon_for could not find mapping",
        message: "condition code: #{condition_code}"
      )

      "question"
    end
  end

  def daily_calendar_events
    return [] unless (days = data.dig(:forecastDaily, :days))

    days.map do |day|
      summary_suffix =
        if day.dig(:precipitationType) == "snow"
          if day.dig(:snowfallAmount) > 0.05
            " / #{(day[:snowfallAmount] * 0.0393701).round(1)}\""
          end
        elsif day.dig(:precipitationAmount).to_f > 0.05
          " / #{(day[:precipitationAmount] * 0.0393701).round(1)}\""
        end

      CalendarEvent.new(
        id: "_weather_day_#{day[:forecastStart]}",
        starts_at: DateTime.parse(day[:forecastStart]).to_i,
        ends_at: DateTime.parse(day[:forecastEnd]).to_i,
        icon: icon_for(day[:conditionCode]),
        summary: "#{celsius_fahrenheit(day[:temperatureMax])}° / #{celsius_fahrenheit(day[:temperatureMin])}°#{summary_suffix}".html_safe
      )
    end
  end

  def celsius_fahrenheit(c)
    (c * 9 / 5 + 32).round
  end
end

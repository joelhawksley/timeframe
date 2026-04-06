# frozen_string_literal: true

class WeatherKitApi
  CACHE_DOMAIN = "weatherkit_api"

  # Map WeatherKit conditionCode to MDI icons (same icons as HomeAssistantApi::CONDITION_ICONS)
  CONDITION_ICONS = {
    "Clear" => "weather-sunny",
    "MostlyClear" => "weather-sunny",
    "PartlyCloudy" => "weather-partly-cloudy",
    "MostlyCloudy" => "cloud",
    "Cloudy" => "cloud",
    "Overcast" => "cloud",
    "Drizzle" => "weather-rainy",
    "Rain" => "weather-rainy",
    "HeavyRain" => "weather-rainy",
    "Snow" => "snowflake",
    "HeavySnow" => "snowflake",
    "Flurries" => "snowflake",
    "FreezingRain" => "snowflake",
    "FreezingDrizzle" => "snowflake",
    "SleetRain" => "snowflake",
    "Sleet" => "snowflake",
    "MixedRainAndSnow" => "snowflake",
    "WintryMix" => "snowflake",
    "Hail" => "weather-hail",
    "Thunderstorms" => "weather-lightning",
    "IsolatedThunderstorms" => "weather-lightning",
    "ScatteredThunderstorms" => "weather-lightning",
    "SevereThunderstorm" => "weather-lightning-rainy",
    "StrongStorms" => "weather-lightning-rainy",
    "Windy" => "weather-windy",
    "Breezy" => "weather-windy",
    "Foggy" => "weather-fog",
    "Haze" => "weather-fog",
    "Smoky" => "weather-fog",
    "Dust" => "weather-fog",
    "BlowingDust" => "weather-fog",
    "Blizzard" => "snowflake",
    "BlowingSnow" => "snowflake",
    "TropicalStorm" => "weather-lightning-rainy",
    "Hurricane" => "weather-lightning-rainy",
    "SunShowers" => "weather-rainy",
    "SunFlurries" => "snowflake"
  }.freeze

  # WeatherKit reports in Celsius and m/s
  WEATHERKIT_TEMP_UNIT = "C"
  WEATHERKIT_SPEED_UNIT_FACTOR = 3.6 # m/s to kph

  def initialize(location:, store: Rails.cache, temperature_unit: "F", speed_unit: "mph", precipitation_unit: "in")
    @location = location
    @store = store
    @temperature_unit = temperature_unit
    @speed_unit = speed_unit
    @precipitation_unit = precipitation_unit
  end

  # :nocov:
  def fetch_weather
    client = Tenkit::Client.new
    weather = client.weather(@location.latitude.to_s, @location.longitude.to_s)

    data = {
      current_weather: serialize_current_weather(weather.current_weather),
      hourly: serialize_hourly(weather.forecast_hourly),
      daily: serialize_daily(weather.forecast_daily),
      alerts: serialize_alerts(weather.weather_alerts)
    }

    save_cache(data)
  rescue => e
    Rails.logger.error "[WeatherKit] Fetch failed for #{@location.name}: #{e.message}"
  end
  # :nocov:

  def weather_healthy?
    fetched = last_fetched_at
    return false unless fetched
    fetched > DateTime.now - 10.minutes
  end

  def current_temperature
    cw = weather_data[:current_weather]
    return nil unless cw

    temp = cw[:temperature_apparent] || cw[:temperature]
    return nil unless temp

    "#{convert_temp(temp.to_f)}°"
  end

  def attribution
    "Apple Weather"
  end

  def time_zone
    @location.time_zone
  end

  def hourly_calendar_events
    today = Date.today.in_time_zone(time_zone)
    hours = weather_data[:hourly] || []
    return [] unless hours.present?

    [today, today.tomorrow, today + 2.days, today + 3.days, today + 4.days, today + 5.days].flat_map do |day|
      [
        (day.noon - 4.hours),
        day.noon,
        (day.noon + 4.hours),
        (day.noon + 8.hours)
      ].map do |hour|
        weather_hour = hours.find { |h| DateTime.parse(h[:datetime]).to_i == hour.to_i }
        next unless weather_hour

        DisplayEvent.new(
          id: "_wk_weather_hour_#{hour.to_i}",
          starts_at: hour,
          ends_at: hour,
          icon: icon_for(weather_hour[:condition]),
          summary: "#{convert_temp(weather_hour[:temperature].to_f)}°"
        )
      end.compact
    end
  end

  def daily_calendar_events
    days = weather_data[:daily] || []
    return [] unless days.present?

    days.map do |day|
      dt = DateTime.parse(day[:datetime])

      DisplayEvent.new(
        id: "_wk_weather_day_#{dt.to_i}",
        starts_at: dt.to_i,
        ends_at: (dt + 1.day).to_i,
        icon: icon_for(day[:condition]),
        summary: "#{convert_temp(day[:temperature_max].to_f)}° / #{convert_temp(day[:temperature_min].to_f)}°"
      )
    end
  end

  def precip_calendar_events
    hours = weather_data[:hourly] || []
    return [] unless hours.present?

    events = []

    hours.each do |hour|
      precip_chance = (hour[:precipitation_chance].to_f * 100).round
      next if precip_chance < 30
      next if hour[:precipitation_amount].to_f == 0.0 && precip_chance < 50

      hour_i = DateTime.parse(hour[:datetime]).to_i
      next if hour_i < Time.now.to_i

      condition = hour[:condition]
      precip_type = %w[Snow HeavySnow Flurries FreezingRain FreezingDrizzle Sleet SleetRain MixedRainAndSnow WintryMix Blizzard BlowingSnow SunFlurries].include?(condition) ? "snow" : "rain"

      existing_event = events.find { |e| e[:end_i] == hour_i && e[:precipitation_type] == precip_type }

      target_unit = if @precipitation_unit == "in"
        "in"
      else
        ((precip_type == "snow") ? "cm" : "mm")
      end

      amount = convert_precipitation(hour[:precipitation_amount].to_f, target_unit)

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:precipitation_total] += amount
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          precipitation_type: precip_type,
          precipitation_total: amount
        }
      end
    end

    events.map do |e|
      icon = (e[:precipitation_type] == "snow") ? "snowflake" : "weather-rainy"
      display_unit = if @precipitation_unit == "in"
        "in"
      else
        ((e[:precipitation_type] == "snow") ? "cm" : "mm")
      end
      amount = e[:precipitation_total]
      label = if amount > 0
        "#{e[:precipitation_type].capitalize} #{format_precipitation(amount, display_unit)}"
      else
        e[:precipitation_type].capitalize
      end

      DisplayEvent.new(
        id: "#{e[:start_i]}_wk_precip",
        starts_at: e[:start_i],
        ends_at: e[:end_i],
        icon: icon,
        summary: label
      )
    end
  end

  def wind_calendar_events
    hours = weather_data[:hourly] || []
    return [] unless hours.present?

    events = []

    hours.each do |hour|
      wind_gust_kph = hour[:wind_gust].to_f * WEATHERKIT_SPEED_UNIT_FACTOR
      wind_gust = convert_speed(wind_gust_kph)
      next if wind_gust < wind_gust_threshold

      hour_i = DateTime.parse(hour[:datetime]).to_i
      next if hour_i < Time.now.to_i

      existing_event = events.find { |e| e[:end_i] == hour_i }

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:wind_max] = [existing_event[:wind_max], wind_gust].max
        existing_event[:wind_directions] << hour[:wind_direction].to_i
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          wind_max: wind_gust,
          wind_directions: [hour[:wind_direction].to_i]
        }
      end
    end

    events.map do |e|
      radians = e[:wind_directions].map { |d| d * Math::PI / 180 }
      avg_x = radians.sum { |r| Math.cos(r) } / radians.size
      avg_y = radians.sum { |r| Math.sin(r) } / radians.size
      avg_wind_direction = (Math.atan2(avg_y, avg_x) * 180 / Math::PI).round

      DisplayEvent.new(
        id: "#{e[:start_i]}_wk_wind",
        starts_at: e[:start_i],
        ends_at: e[:end_i],
        icon: "arrow-up",
        icon_rotation: avg_wind_direction,
        summary: "Gusts up to #{e[:wind_max].round}#{@speed_unit}"
      )
    end
  end

  def weather_alert_events
    alerts = weather_data[:alerts] || []
    return [] unless alerts.present?

    alerts.map do |alert|
      DisplayEvent.new(
        id: "_wk_alert_#{alert[:id]}",
        starts_at: alert[:effective_time],
        ends_at: alert[:expire_time],
        icon: "alert",
        summary: alert[:description]
      )
    end
  end

  private

  def icon_for(condition)
    CONDITION_ICONS[condition] || "help-circle"
  end

  def convert_temp(celsius)
    if @temperature_unit == "C"
      celsius.round
    else
      (celsius * 9.0 / 5.0 + 32).round
    end
  end

  def convert_speed(kph)
    if @speed_unit == "mph"
      kph * 0.621371
    else
      kph
    end
  end

  def wind_gust_threshold
    (@speed_unit == "kph") ? 32.0 : 20.0
  end

  # WeatherKit reports precipitation in mm
  def convert_precipitation(mm, target_unit)
    case target_unit
    when "in" then mm / 25.4
    when "cm" then mm / 10.0
    else mm
    end
  end

  def format_precipitation(amount, unit)
    rounded = sprintf("%.1f", amount)
    label = (unit == "in") ? "\"" : unit
    "#{rounded}#{label}"
  end

  def cache_key
    "#{DEPLOY_TIME}#{CACHE_DOMAIN}_#{@location.id}"
  end

  # :nocov:
  def save_cache(data)
    @store.write(cache_key, {last_fetched_at: Time.now.utc, response: data}.to_json)
  end
  # :nocov:

  def cache_value
    JSON.parse(@store.read(cache_key) || "{}", symbolize_names: true)
  end

  def weather_data
    cache_value[:response] || {}
  end

  def last_fetched_at
    val = cache_value
    val[:last_fetched_at].present? ? DateTime.parse(val[:last_fetched_at]) : nil
  end

  # :nocov:
  def serialize_current_weather(cw)
    return nil unless cw
    {
      temperature: cw.temperature,
      temperature_apparent: cw.temperature_apparent,
      condition: cw.condition_code,
      humidity: cw.humidity,
      wind_speed: cw.wind_speed,
      wind_gust: cw.wind_gust,
      wind_direction: cw.wind_direction
    }
  end

  def serialize_hourly(forecast)
    return [] unless forecast&.hours
    forecast.hours.map do |h|
      {
        datetime: h.forecast_start,
        temperature: h.temperature,
        condition: h.condition_code,
        precipitation_chance: h.precipitation_chance,
        precipitation_amount: h.precipitation_amount,
        wind_speed: h.wind_speed,
        wind_gust: h.wind_gust,
        wind_direction: h.wind_direction
      }
    end
  end

  def serialize_daily(forecast)
    return [] unless forecast&.days
    forecast.days.map do |d|
      {
        datetime: d.forecast_start,
        condition: d.condition_code,
        temperature_max: d.temperature_max,
        temperature_min: d.temperature_min,
        precipitation_chance: d.precipitation_chance,
        precipitation_amount: d.precipitation_amount
      }
    end
  end

  def serialize_alerts(alert_collection)
    return [] unless alert_collection&.alerts
    alert_collection.alerts.map do |a|
      {
        id: a.id,
        description: a.description,
        effective_time: a.effective_time,
        expire_time: a.expire_time,
        severity: a.severity,
        source: a.source
      }
    end
  end
  # :nocov:
end

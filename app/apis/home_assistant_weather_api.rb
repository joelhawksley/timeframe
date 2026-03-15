class HomeAssistantWeatherApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def url
    "#{home_assistant_base_url}/api/services/weather/get_forecasts?return_response"
  end

  def fetch
    ha_api = HomeAssistantApi.new(@config)
    entity_id = ha_api.weather_entity_id
    return unless entity_id.present?

    hourly = fetch_forecast(entity_id, "hourly")
    daily = fetch_forecast(entity_id, "daily")

    return unless hourly.present? || daily.present?

    entity = ha_api.data.find { it[:entity_id] == entity_id }
    attribution = entity&.dig(:attributes, :attribution)

    save_response({
      entity_id: entity_id,
      hourly: hourly,
      daily: daily,
      attribution: attribution
    })
  end

  def prepare_response(response)
    response
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def hourly_forecast
    data[:hourly] || []
  end

  def attribution
    data[:attribution]&.gsub(%r{\s*https?://\S+}, "")&.strip
  end

  def daily_forecast
    data[:daily] || []
  end

  CONDITION_ICONS = {
    "cloudy" => "cloud",
    "partlycloudy" => "weather-partly-cloudy",
    "sunny" => "weather-sunny",
    "clear-night" => "weather-night",
    "rainy" => "weather-rainy",
    "pouring" => "weather-rainy",
    "snowy" => "snowflake",
    "snowy-rainy" => "snowflake",
    "hail" => "weather-hail",
    "lightning" => "weather-lightning",
    "lightning-rainy" => "weather-lightning-rainy",
    "windy" => "weather-windy",
    "windy-variant" => "weather-windy-variant",
    "fog" => "weather-fog",
    "exceptional" => "alert"
  }.freeze

  def icon_for(condition)
    CONDITION_ICONS[condition] || "help-circle"
  end

  def speed_unit
    @config["speed_unit"] || "mph"
  end

  def precipitation_unit
    @config["precipitation_unit"] || "in"
  end

  def temperature_unit
    @config["temperature_unit"] || "F"
  end

  def ha_config
    @ha_config ||= HomeAssistantConfigApi.new(@config)
  end

  def convert_speed(value)
    ha_unit = ha_config.ha_speed_unit
    return value.to_f if ha_unit == speed_unit

    if ha_unit == "kph" && speed_unit == "mph"
      value.to_f * 0.621371
    else
      value.to_f * 1.60934
    end
  end

  def convert_temperature(value)
    ha_unit = ha_config.ha_temperature_unit
    return value.to_i if ha_unit == temperature_unit

    if ha_unit == "C" && temperature_unit == "F"
      (value.to_f * 9.0 / 5.0 + 32).round
    else
      ((value.to_f - 32) * 5.0 / 9.0).round
    end
  end

  def convert_precipitation(value, target_unit)
    ha_unit = ha_config.ha_precipitation_unit
    return value.to_f if ha_unit == target_unit

    case [ha_unit, target_unit]
    when ["mm", "in"] then value.to_f / 25.4
    when ["mm", "cm"] then value.to_f / 10.0
    when ["cm", "in"] then value.to_f / 2.54
    when ["cm", "mm"] then value.to_f * 10.0
    when ["in", "mm"] then value.to_f * 25.4
    when ["in", "cm"] then value.to_f * 2.54
    else value.to_f
    end
  end

  def wind_gust_threshold
    (speed_unit == "kph") ? 32.0 : 20.0
  end

  def hourly_calendar_events
    today = Date.today.in_time_zone(HomeAssistantConfigApi.new.time_zone)
    hours = hourly_forecast

    return [] unless hours.present?

    [today, today.tomorrow, today + 2.days, today + 3.days, today + 4.days, today + 5.days].flat_map do |day|
      [
        (day.noon - 4.hours),
        day.noon,
        (day.noon + 4.hours),
        (day.noon + 8.hours)
      ].map do |hour|
        hour_str = hour.utc.iso8601
        weather_hour = hours.find { it[:datetime] == hour_str }

        next unless weather_hour.present?

        CalendarEvent.new(
          id: "_ha_weather_hour_#{hour.to_i}",
          starts_at: hour,
          ends_at: hour,
          icon: icon_for(weather_hour[:condition]),
          summary: "#{convert_temperature(weather_hour[:temperature])}°"
        )
      end.compact
    end
  end

  def daily_calendar_events
    days = daily_forecast

    return [] unless days.present?

    days.map do |day|
      dt = DateTime.parse(day[:datetime])

      CalendarEvent.new(
        id: "_ha_weather_day_#{dt.to_i}",
        starts_at: dt.to_i,
        ends_at: (dt + 1.day).to_i,
        icon: icon_for(day[:condition]),
        summary: "#{convert_temperature(day[:temperature])}° / #{convert_temperature(day[:templow])}°"
      )
    end
  end

  def precip_calendar_events
    hours = hourly_forecast
    return [] unless hours.present?

    events = []

    hours.each do |hour|
      next if hour[:precipitation_probability].to_i < 30
      next if hour[:precipitation].to_f == 0.0 && hour[:precipitation_probability].to_i < 50

      hour_i = DateTime.parse(hour[:datetime]).to_i
      next if hour_i < Time.now.to_i

      condition = hour[:condition]
      precip_type = %w[snowy snowy-rainy].include?(condition) ? "snow" : "rain"

      existing_event = events.find { it[:end_i] == hour_i && it[:precipitation_type] == precip_type }

      target_unit = if precipitation_unit == "in"
        "in"
      else
        (precip_type == "snow") ? "cm" : "mm"
      end

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:precipitation_total] += convert_precipitation(hour[:precipitation], target_unit)
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          precipitation_type: precip_type,
          precipitation_total: convert_precipitation(hour[:precipitation], target_unit)
        }
      end
    end

    events.map do
      icon = (it[:precipitation_type] == "snow") ? "snowflake" : "weather-rainy"
      display_unit = if precipitation_unit == "in"
        "in"
      else
        (it[:precipitation_type] == "snow") ? "cm" : "mm"
      end
      amount = it[:precipitation_total]
      label = if amount > 0
        "#{it[:precipitation_type].capitalize} #{format_precipitation(amount, display_unit)}"
      else
        it[:precipitation_type].capitalize
      end

      CalendarEvent.new(
        id: "#{it[:start_i]}_ha_precip",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: icon,
        summary: label
      )
    end
  end

  def wind_calendar_events
    hours = hourly_forecast
    return [] unless hours.present?

    events = []

    hours.each do |hour|
      wind_gust = convert_speed(hour[:wind_gust_speed])
      next if wind_gust < wind_gust_threshold

      hour_i = DateTime.parse(hour[:datetime]).to_i
      next if hour_i < Time.now.to_i

      existing_event = events.find { it[:end_i] == hour_i }

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:wind_max] = [existing_event[:wind_max], wind_gust].max
        existing_event[:wind_directions] << hour[:wind_bearing].to_i
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          wind_max: wind_gust,
          wind_directions: [hour[:wind_bearing].to_i]
        }
      end
    end

    events.map do
      radians = it[:wind_directions].map { |d| d * Math::PI / 180 }
      avg_x = radians.sum { |r| Math.cos(r) } / radians.size
      avg_y = radians.sum { |r| Math.sin(r) } / radians.size
      avg_wind_direction = (Math.atan2(avg_y, avg_x) * 180 / Math::PI).round

      CalendarEvent.new(
        id: "#{it[:start_i]}_ha_wind",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: "arrow-up",
        icon_rotation: avg_wind_direction,
        summary: "Gusts up to #{it[:wind_max].round}#{speed_unit}"
      )
    end
  end

  private

  def format_precipitation(amount, unit)
    rounded = sprintf("%.1f", amount)
    label = (unit == "in") ? "\"" : unit
    "#{rounded}#{label}"
  end

  def fetch_forecast(entity_id, forecast_type)
    response = HTTParty.post(
      url,
      headers: headers,
      body: {
        entity_id: entity_id,
        type: forecast_type
      }.to_json
    )

    return nil unless response.code == 200

    parsed = response.parsed_response
    parsed.dig("service_response", entity_id, "forecast")
  rescue
    nil
  end
end

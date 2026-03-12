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
          summary: "#{weather_hour[:temperature].to_i}°"
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
        summary: "#{day[:temperature].to_i}° / #{day[:templow].to_i}°"
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

      if existing_event
        existing_event[:end_i] += 3600
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          precipitation_type: precip_type
        }
      end
    end

    events.map do
      icon = (it[:precipitation_type] == "snow") ? "snowflake" : "weather-rainy"

      CalendarEvent.new(
        id: "#{it[:start_i]}_ha_precip",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: icon,
        summary: it[:precipitation_type].capitalize
      )
    end
  end

  def wind_calendar_events
    hours = hourly_forecast
    return [] unless hours.present?

    events = []

    hours.each do |hour|
      wind_gust_mph = hour[:wind_gust_speed].to_f * 0.621371 # km/h to mph
      next if wind_gust_mph < 20.0

      hour_i = DateTime.parse(hour[:datetime]).to_i
      next if hour_i < Time.now.to_i

      existing_event = events.find { it[:end_i] == hour_i }

      if existing_event
        existing_event[:end_i] += 3600
        existing_event[:wind_max] = [existing_event[:wind_max], wind_gust_mph].max
        existing_event[:wind_directions] << hour[:wind_bearing].to_i
      else
        events << {
          start_i: hour_i,
          end_i: hour_i + 3600,
          wind_max: wind_gust_mph,
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
        summary: "Gusts up to #{it[:wind_max].round}mph"
      )
    end
  end

  private

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

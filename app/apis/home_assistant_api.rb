class HomeAssistantApi
  MDI_CSS = File.read(Rails.root.join("public/css/mdi/materialdesignicons.css")).freeze
  DEFAULT_HOME_ASSISTANT_URL = "http://homeassistant.local:8123"

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

  STATES_DOMAIN = "home_assistant_api"
  CONFIG_DOMAIN = "home_assistant_config_api"
  CALENDAR_DOMAIN = "home_assistant_calendar_api"
  WEATHER_DOMAIN = "home_assistant_weather_api"

  def initialize(config = Timeframe::Application.config.local, store: Rails.cache)
    @config = config
    @store = store
  end

  def home_assistant_base_url
    @config&.fetch("home_assistant_url", nil) || DEFAULT_HOME_ASSISTANT_URL
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  # --- States ---

  def fetch_states
    response = HTTParty.get("#{home_assistant_base_url}/api/states", headers: headers)
    return if response.code != 200
    save_domain(STATES_DOMAIN, JSON.parse(response.body))
  end

  def states_healthy?
    fetched = states_last_fetched_at
    return false unless fetched
    fetched > DateTime.now - 1.minute
  end

  def states_last_fetched_at
    domain_last_fetched_at(STATES_DOMAIN)
  end

  def data
    domain_data(STATES_DOMAIN)
  end

  def top_right
    data
      .select { it[:entity_id].start_with?("sensor.timeframe_top_right") && it[:state].present? }
      .filter_map do
        parts = it[:state].split(",").map(&:strip)
        next if parts.length < 2

        {icon: parts.first, label: parts.last.then { it.include?("_") ? it.humanize : it }}
      end
  end

  def top_left
    data
      .select { it[:entity_id].start_with?("sensor.timeframe_top_left") && it[:state].present? }
      .filter_map do
        parts = it[:state].split(",").map(&:strip)
        next if parts.length < 2

        {icon: parts.first, label: parts.last.then { it.include?("_") ? it.humanize : it }}
      end
  end

  def weather_status
    data
      .select { it[:entity_id].start_with?("sensor.timeframe_weather_status") && it[:state].present? }
      .filter_map do
        parts = it[:state].split(",").map(&:strip)
        next if parts.length < 2

        result = {icon: parts.first, label: parts[1].then { it.include?("_") ? it.humanize : it }}
        result[:rotation] = parts[2].to_i if parts.length >= 3
        result
      end
  end

  def daily_events(current_time: Time.now.in_time_zone(time_zone))
    today = current_time.to_date

    data
      .select { it[:entity_id].start_with?("sensor.timeframe_daily_event") && it[:state].present? }
      .filter_map do
        parts = it[:state].split(",").map(&:strip)
        next if parts.length < 2

        DisplayEvent.new(
          id: "_daily_event_#{it[:entity_id]}",
          starts_at: today.to_time,
          ends_at: (today + 1.day).to_time,
          icon: parts.first,
          summary: parts.last.then { it.include?("_") ? it.humanize : it }
        )
      end
  end

  def now_playing
    override = data.find { it[:entity_id].end_with?("timeframe_media_player_entity_id") }

    entity = if override.present? && override[:state].present?
      data.find { it[:entity_id] == override[:state] }
    else
      data.find { it[:entity_id].start_with?("media_player.") }
    end

    return {} unless entity.present?
    return {} if %w[paused idle].include?(entity[:state])

    attrs = entity[:attributes] || {}
    artist = attrs[:media_artist]
    track = attrs[:media_title]
    return {} unless artist.present? || track.present?

    {
      artist: artist,
      track: track
    }
  end

  def weather_entity_id
    override = data.find { it[:entity_id].end_with?("timeframe_weather_entity_id") }
    return override[:state] if override.present? && override[:state].present?

    weather = data.find { it[:entity_id].start_with?("weather.") }
    weather&.dig(:entity_id)
  end

  def feels_like_temperature
    ha_unit = ha_temperature_unit
    display_unit = @config["temperature_unit"] || "F"

    override = data.find { it[:entity_id].end_with?("timeframe_weather_feels_like_entity_id") }

    if override.present? && override[:state].present?
      entity = data.find { it[:entity_id] == override[:state] }
      return "#{convert_temp(entity[:state].to_f, ha_unit, display_unit)}°" if entity.present?
    end

    weather = data.find { it[:entity_id] == weather_entity_id }
    apparent = weather&.dig(:attributes, :apparent_temperature)
    return "#{convert_temp(apparent.to_f, ha_unit, display_unit)}°" if apparent.present?

    nil
  end

  # --- Config ---

  def fetch_config
    response = HTTParty.get("#{home_assistant_base_url}/api/config", headers: headers)
    return if response.code != 200
    save_domain(CONFIG_DOMAIN, JSON.parse(response.body))
  end

  def config_healthy?
    fetched = config_last_fetched_at
    return false unless fetched
    fetched > DateTime.now - 10.minutes
  end

  def config_last_fetched_at
    domain_last_fetched_at(CONFIG_DOMAIN)
  end

  def config_data
    domain_data(CONFIG_DOMAIN)
  end

  def latitude
    config_data[:latitude]&.to_s
  end

  def longitude
    config_data[:longitude]&.to_s
  end

  def time_zone
    config_data[:time_zone]
  end

  def unit_system
    config_data[:unit_system] || {}
  end

  def ha_speed_unit
    case unit_system[:wind_speed]
    when "km/h" then "kph"
    else "mph"
    end
  end

  def ha_temperature_unit
    (unit_system[:temperature] == "°C") ? "C" : "F"
  end

  def ha_precipitation_unit
    case unit_system[:accumulated_precipitation]
    when "mm" then "mm"
    when "cm" then "cm"
    else "in"
    end
  end

  # --- Calendars ---

  def fetch_calendars
    start_time = (Time.now - 1.day).utc.iso8601
    end_time = (Time.now + 5.days).utc.iso8601

    calendars_url = "#{home_assistant_base_url}/api/calendars"

    out = []
    calendars = fetch_calendar_list
    icons = fetch_calendar_icons(calendars)

    calendars.each do |calendar|
      entity_id = calendar["entity_id"]

      res = HTTParty.get("#{calendars_url}/#{entity_id}?start=#{start_time}&end=#{end_time}", headers: headers)

      res.map! do |event|
        event["starts_at"] = event["start"]["date"] || event["start"]["dateTime"]
        event["ends_at"] = event["end"]["date"] || event["end"]["dateTime"]
        event["icon"] = icons[entity_id] || "calendar"
        event["id"] = event["uid"]
        event.delete("uid")
        event.delete("start")
        event.delete("end")
        event.delete("recurrence_id")
        event.delete("rrule")
        event
      end

      out.concat(res)
    end

    save_domain(CALENDAR_DOMAIN, out.compact)
  end

  def calendars_healthy?
    fetched = calendars_last_fetched_at
    return false unless fetched
    fetched > DateTime.now - 10.minutes
  end

  def calendars_last_fetched_at
    domain_last_fetched_at(CALENDAR_DOMAIN)
  end

  def calendar_events
    @calendar_events ||= (domain_value(CALENDAR_DOMAIN)[:response] || []).map { DisplayEvent.new(**it.symbolize_keys!) }
  end

  def fetch_calendar_list
    res = HTTParty.get("#{home_assistant_base_url}/api/calendars", headers: headers)
    return [] unless res.code == 200
    res.parsed_response
  end

  def fetch_calendar_icons(calendars)
    states_url = "#{home_assistant_base_url}/api/states"
    icons = {}

    calendars.each do |calendar|
      entity_id = calendar["entity_id"]

      begin
        res = HTTParty.get("#{states_url}/#{entity_id}", headers: headers)
        if res.code == 200
          icon = res.dig("attributes", "icon")
          if icon.present?
            icon_name = icon.sub("mdi:", "")
            icons[entity_id] = icon_name if MDI_CSS.include?(".mdi-#{icon_name}::before")
          end
        end
      rescue
        # Fall back to default icon if state lookup fails
      end
    end

    icons
  end

  def private_mode?
    current_time = DateTime.now.in_time_zone(time_zone)

    calendar_events.any? { it.summary == "timeframe-private" && it.starts_at <= current_time && it.ends_at >= current_time }
  end

  # --- Weather ---

  def fetch_weather
    entity_id = weather_entity_id
    return unless entity_id.present?

    hourly = fetch_forecast(entity_id, "hourly")
    daily = fetch_forecast(entity_id, "daily")

    return unless hourly.present? || daily.present?

    entity = data.find { it[:entity_id] == entity_id }
    attribution_value = entity&.dig(:attributes, :attribution)

    save_domain(WEATHER_DOMAIN, {
      entity_id: entity_id,
      hourly: hourly,
      daily: daily,
      attribution: attribution_value
    })
  end

  def weather_healthy?
    fetched = weather_last_fetched_at
    return false unless fetched
    fetched > DateTime.now - 10.minutes
  end

  def weather_last_fetched_at
    domain_last_fetched_at(WEATHER_DOMAIN)
  end

  def weather_data
    domain_data(WEATHER_DOMAIN)
  end

  def hourly_forecast
    weather_data[:hourly] || []
  end

  def attribution
    weather_data[:attribution]&.gsub(%r{\s*https?://\S+}, "")&.strip
  end

  def daily_forecast
    weather_data[:daily] || []
  end

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

  def convert_speed(value)
    ha_unit = ha_speed_unit
    return value.to_f if ha_unit == speed_unit

    if ha_unit == "kph" && speed_unit == "mph"
      value.to_f * 0.621371
    else
      value.to_f * 1.60934
    end
  end

  def convert_temperature(value)
    ha_unit = ha_temperature_unit
    return value.to_i if ha_unit == temperature_unit

    if ha_unit == "C" && temperature_unit == "F"
      (value.to_f * 9.0 / 5.0 + 32).round
    else
      ((value.to_f - 32) * 5.0 / 9.0).round
    end
  end

  def convert_precipitation(value, target_unit)
    ha_unit = ha_precipitation_unit
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
    today = Date.today.in_time_zone(time_zone)
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

        DisplayEvent.new(
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

      DisplayEvent.new(
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

      DisplayEvent.new(
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

      DisplayEvent.new(
        id: "#{it[:start_i]}_ha_wind",
        starts_at: it[:start_i],
        ends_at: it[:end_i],
        icon: "arrow-up",
        icon_rotation: avg_wind_direction,
        summary: "Gusts up to #{it[:wind_max].round}#{speed_unit}"
      )
    end
  end

  def seed_states(data)
    save_domain(STATES_DOMAIN, data)
  end

  def seed_config(data)
    save_domain(CONFIG_DOMAIN, data)
  end

  def seed_calendars(data)
    save_domain(CALENDAR_DOMAIN, data)
  end

  def seed_weather(data)
    save_domain(WEATHER_DOMAIN, data)
  end

  private

  def storage_key(domain)
    "#{DEPLOY_TIME}#{domain}"
  end

  def save_domain(domain, data)
    @store.write(storage_key(domain), {last_fetched_at: Time.now.utc, response: data}.to_json)
  end

  def domain_value(domain)
    JSON.parse(@store.read(storage_key(domain)) || "{}", symbolize_names: true)
  end

  def domain_data(domain)
    domain_value(domain)[:response] || {}
  end

  def domain_last_fetched_at(domain)
    val = domain_value(domain)
    val[:last_fetched_at].present? ? DateTime.parse(val[:last_fetched_at]) : nil
  end

  def convert_temp(value, from, to)
    return value.round if from == to

    if from == "C" && to == "F"
      (value * 9.0 / 5.0 + 32).round
    else
      ((value - 32) * 5.0 / 9.0).round
    end
  end

  def format_precipitation(amount, unit)
    rounded = sprintf("%.1f", amount)
    label = (unit == "in") ? "\"" : unit
    "#{rounded}#{label}"
  end

  def fetch_forecast(entity_id, forecast_type)
    response = HTTParty.post(
      "#{home_assistant_base_url}/api/services/weather/get_forecasts?return_response",
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

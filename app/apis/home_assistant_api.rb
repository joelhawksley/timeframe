class HomeAssistantApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def demo_mode?
    entity = data.find { it[:entity_id].end_with?(".timeframe_demo_mode") }
    return false unless entity.present?

    entity[:state] == "on"
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

  def daily_events(current_time: Time.now.in_time_zone(HomeAssistantConfigApi.new.time_zone))
    today = current_time.to_date

    data
      .select { it[:entity_id].start_with?("sensor.timeframe_daily_event") && it[:state].present? }
      .filter_map do
        parts = it[:state].split(",").map(&:strip)
        next if parts.length < 2

        CalendarEvent.new(
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

  def time_before_unhealthy
    1.minute
  end

  def weather_entity_id
    fetch
    
    # First, look for a sensor whose entity_id ends with timeframe_weather_entity_id
    override = data.find { it[:entity_id].end_with?("timeframe_weather_entity_id") }
    return override[:state] if override.present? && override[:state].present?

    # Fall back to the first weather.* entity
    weather = data.find { it[:entity_id].start_with?("weather.") }
    weather&.dig(:entity_id)
  end

  def feels_like_temperature
    # First, look for a sensor whose entity_id ends with timeframe_weather_feels_like_entity_id
    override = data.find { it[:entity_id].end_with?("timeframe_weather_feels_like_entity_id") }

    if override.present? && override[:state].present?
      entity = data.find { it[:entity_id] == override[:state] }
      return "#{entity[:state].to_i}°" if entity.present?
    end

    # Fall back to apparent_temperature attribute from the weather entity
    weather = data.find { it[:entity_id] == weather_entity_id }
    apparent = weather&.dig(:attributes, :apparent_temperature)
    return "#{apparent.to_i}°" if apparent.present?

    nil
  end
end

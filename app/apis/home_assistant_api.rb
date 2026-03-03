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

  def prepare_response(response)
    entity_ids = @config["home_assistant"].values.flatten

    # Only save entity states we are interested in vs. all 1000+ entities
    response.filter do
      entity_ids.include?(it["entity_id"]) ||
        it["entity_id"].include?("sensor.timeframe") ||
        it["state"] == "unavailable" && !it["entity_id"].include?("image.")
    end
  end

  def demo_mode?
    return false unless @config["home_assistant"].present?

    entity = data.find { it[:entity_id] == @config["home_assistant"]["demo_mode_entity_id"] }
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
    entity = data.find { it[:entity_id] == @config["home_assistant"]["media_player_entity_id"] }

    return {} unless entity.present?
    return {} if entity[:state] == "paused" || entity[:state] == "idle"

    if entity.dig(:attributes, :media_artist)&.include?("CPR News")
      {
        artist: "CPR News",
        track: entity.dig(:attributes, :media_title).split(" -- ").last
      }
    elsif entity.dig(:attributes, :media_channel)&.include?("Colorado Public Radio Classical")
      track, artist = entity.dig(:attributes, :media_title).split(" -- ").first.split(" by ")

      {
        artist: artist,
        track: track
      }
    elsif entity.dig(:attributes, :media_channel)&.include?("WKSU-HD2")
      title_parts = entity.dig(:attributes, :media_title).split(" - ")

      {
        artist: title_parts[0],
        track: title_parts[1]
      }
    else
      {
        artist: entity.dig(:attributes, :media_artist),
        track: entity.dig(:attributes, :media_title)
      }
    end
  end

  def time_before_unhealthy
    1.minute
  end

  def feels_like_temperature
    entity = data.find { it[:entity_id] == @config["home_assistant"]["weather_feels_like_entity_id"] }

    return nil unless entity.present?

    "#{entity[:state].to_i}°"
  end
end

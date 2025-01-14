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
      entity_ids.include?(_1["entity_id"]) ||
        _1.dig("attributes", "device_class") == "battery" ||
        _1["entity_id"].include?("binary_sensor.timeframe")
    end
  end

  def problems
    data
      .select { _1[:entity_id].include?("binary_sensor.timeframe") && _1[:state] == "on" }
      .map { _1[:entity_id] }
      .map do |entity_id|
        _, icon, raw_message = entity_id.split("0")

        {
          icon: icon.tr("_", "-"),
          message: raw_message.tr("_", " ").humanize
        }
      end
  end

  def now_playing
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["media_player_entity_id"] }

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
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["weather_feels_like_entity_id"] }

    return nil unless entity.present?

    "#{entity[:state].to_i}°"
  end

  def unavailable_door_sensors
    out = []

    @config["home_assistant"]["exterior_door_sensors"].each do |entity_id|
      if data.find { _1[:entity_id] == entity_id }&.fetch(:state) == "unavailable"
        out << entity_id.split(".").last.gsub("_opening", "").humanize
      end
    end

    out.uniq
  end

  def roborock_errors
    out = []

    entity = data.find { _1[:entity_id] == @config["home_assistant"]["roborock_dock_error"] }

    if entity.present? && entity[:state] != "ok"
      out << entity[:state].humanize
    end

    entity = data.find { _1[:entity_id] == @config["home_assistant"]["roborock_vacuum_error"] }

    if entity.present? && entity[:state] != "none"
      out << entity[:state].humanize
    end

    entity = data.find { _1[:entity_id] == @config["home_assistant"]["roborock_status"] }

    if entity.present? && ["idle", "charger_disconnected"].include?(entity[:state])
      out << "Return to charger"
    end

    entity = data.find { _1[:entity_id] == @config["home_assistant"]["roborock_sensor_time_left"] }

    if entity.present? && entity[:state].to_i <= 0
      out << "Sensor maintenance"
    end

    out.uniq
  end

  def open_doors
    out = []

    @config["home_assistant"]["exterior_door_sensors"].map do |entity_id|
      if data.find { _1[:entity_id] == entity_id }&.fetch(:state) == "on"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out
  end

  def unlocked_doors
    out = []

    @config["home_assistant"]["exterior_door_locks"].map do |entity_id|
      if data.find { _1[:entity_id] == entity_id }&.fetch(:state) == "off"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out - open_doors
  end

  def low_batteries
    out = []

    data.select { _1.dig(:attributes, :device_class) == "battery" }.each do |entity|
      next if entity[:state] == "unknown" || entity[:state] == "unavailable"

      if entity[:state].to_f <= 5
        out << entity[:entity_id].split(".").last.split("_battery").first.humanize
      end
    end

    out
  end

  def online?
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["ping_sensor_entity_id"] }

    return false unless entity.present?

    entity[:state] == "on"
  end

  def nas_online?
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["nas_temperature_entity_id"] }

    return false unless entity.present?

    entity[:state].to_i > 0
  end
end

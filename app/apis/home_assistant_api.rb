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
      !@config["home_assistant"]["ignored_entity_ids"].include?(_1["entity_id"]) &&
        (entity_ids.include?(_1["entity_id"]) || _1.dig("attributes", "device_class") == "battery")
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

  def dryer_needs_attention?
    door_entity = data.find { _1[:entity_id] == @config["home_assistant"]["dryer_door_entity_id"] }
    state_entity = data.find { _1[:entity_id] == @config["home_assistant"]["dryer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity[:state] == "off" &&
      state_entity[:state] == "Off" &&
      Time.parse(state_entity[:last_changed]) > Time.parse(door_entity[:last_changed])
  end

  def washer_needs_attention?
    door_entity = data.find { _1[:entity_id] == @config["home_assistant"]["washer_door_entity_id"] }
    state_entity = data.find { _1[:entity_id] == @config["home_assistant"]["washer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity[:state] == "off" &&
      state_entity[:state] == "Off" &&
      Time.parse(state_entity[:last_changed]) > Time.parse(door_entity[:last_changed])
  end

  def garage_door_open?
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["garage_door_entity_id"] }
    entity_2 = data.find { _1[:entity_id] == @config["home_assistant"]["garage_door_2_entity_id"] }

    return false unless entity.present? && entity_2.present?

    entity[:state] == "open" || entity_2[:state] == "open"
  end

  def car_needs_plugged_in?
    rav4_entity = data.find { _1[:entity_id] == @config["home_assistant"]["rav4_entity_id"] }
    west_charger_entity = data.find { _1[:entity_id] == @config["home_assistant"]["west_charger_entity_id"] }

    return false unless rav4_entity.present? && west_charger_entity.present?

    rav4_entity[:state] == "garage" && west_charger_entity[:state] == "not_connected"
  end

  def package_present?
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["package_box_entity_id"] }

    return false unless entity.present?

    entity[:state] == "on"
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

  def active_video_call?
    entity = data.find { _1[:entity_id] == @config["home_assistant"]["audio_input_in_use"] }

    return false unless entity.present?

    entity[:state] == "on"
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

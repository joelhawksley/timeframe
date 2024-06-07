class HomeAssistantApi < Api
  def headers
    {
      Authorization: "Bearer #{Timeframe::Application.config.local["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def time_before_unhealthy
    1.minute
  end

  def feels_like_temperature
    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_weather_feels_like_entity_id"] }

    return nil unless entity.present?

    entity["state"].to_i
  end

  def dryer_needs_attention?
    door_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_dryer_door_entity_id"] }
    state_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_dryer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity["state"] == "off" &&
      state_entity["state"] == "Off" &&
      Time.parse(state_entity["last_changed"]) > Time.parse(door_entity["last_changed"])
  end

  def washer_needs_attention?
    door_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_washer_door_entity_id"] }
    state_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_washer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity["state"] == "off" &&
      state_entity["state"] == "Off" &&
      Time.parse(state_entity["last_changed"]) > Time.parse(door_entity["last_changed"])
  end

  def garage_door_open?
    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_entity_id"] }
    entity_2 = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"] }

    return false unless entity.present? && entity_2.present?

    entity["state"] == "open" || entity_2["state"] == "open"
  end

  def car_needs_plugged_in?
    rav4_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_rav4_entity_id"] }
    west_charger_entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_west_charger_entity_id"] }

    return false unless rav4_entity.present? && west_charger_entity.present?

    rav4_entity["state"] == "garage" && west_charger_entity["state"] == "not_connected"
  end

  def package_present?
    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_package_box_entity_id"] }

    return false unless entity.present?

    entity["state"] == "on"
  end

  def unavailable_door_sensors
    out = []

    Timeframe::Application.config.local["exterior_door_sensors"].concat(
      Timeframe::Application.config.local["exterior_door_locks"]
    ).each do |entity_id|
      if data.find { _1["entity_id"] == entity_id }&.fetch("state") == "unavailable"
        out << entity_id.split(".").last.gsub("_opening", "").humanize
      end
    end

    out.uniq
  end

  def roborock_errors
    out = []

    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_roborock_dock_error"] }

    if entity.present? && entity["state"] != "ok"
      out << entity["state"].humanize
    end

    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_roborock_vacuum_error"] }

    if entity.present? && entity["state"] != "none"
      out << entity["state"].humanize
    end


    out.uniq
  end

  def open_doors
    out = []

    Timeframe::Application.config.local["exterior_door_sensors"].map do |entity_id|
      if data.find { _1["entity_id"] == entity_id }&.fetch("state") == "on"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out
  end

  def unlocked_doors
    out = []

    Timeframe::Application.config.local["exterior_door_locks"].map do |entity_id|
      if data.find { _1["entity_id"] == entity_id }&.fetch("state") == "unlocked"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out - open_doors
  end

  def low_batteries
    out = []

    data.select { _1.dig("attributes", "device_class") == "battery" }.each do |entity|
      next if entity["state"] == "unknown" || entity["state"] == "unavailable"
      
      if entity["state"].to_f <= 5
        out << entity["entity_id"].split(".").last.split("_battery").first.humanize
      end
    end

    out
  end

  def active_video_call?
    entity = data.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_audio_input_in_use"] }

    return false unless entity.present?

    entity["state"] == "on"
  end
end

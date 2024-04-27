class HomeAssistantHome
  def self.fetch
    response = HTTParty.get(
      "http://homeassistant.local:8123/api/states",
      headers: {
        Authorization: "Bearer #{Timeframe::Application.config.local["home_assistant_token"]}",
        "content-type": "application/json"
      }
    ).body

    MemoryValue.upsert(:home_assistant,
      {
        states: JSON.parse(response),
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      })
  end

  def self.states
    MemoryValue.get(:home_assistant)[:states] || []
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 1.minute
  end

  # :nocov:
  def self.last_fetched_at
    MemoryValue.get(:home_assistant)[:last_fetched_at]
  end
  # :nocov:

  def self.feels_like_temperature
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_weather_feels_like_entity_id"] }

    return nil unless entity.present?

    entity["state"].to_i
  end

  def self.hot_water_heater_healthy?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_available_hot_water_entity_id"] }

    return nil unless entity.present?

    entity["state"].to_i > 10
  end

  def self.dryer_needs_attention?
    door_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_dryer_door_entity_id"] }
    state_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_dryer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity["state"] == "off" &&
    state_entity["state"] == "Off" &&
    Time.parse(state_entity["last_changed"]) > Time.parse(door_entity["last_changed"])
  end

  def self.washer_needs_attention?
    door_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_washer_door_entity_id"] }
    state_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_washer_state_entity_id"] }

    return nil unless door_entity.present? && state_entity.present?

    door_entity["state"] == "off" &&
    state_entity["state"] == "Off" &&
    Time.parse(state_entity["last_changed"]) > Time.parse(door_entity["last_changed"])
  end

  def self.garage_door_open?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_entity_id"] }
    entity_2 = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"] }

    return false unless entity.present? && entity_2.present?

    entity["state"] == "open" || entity_2["state"] == "open"
  end

  def self.car_needs_plugged_in?
    rav4_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_rav4_entity_id"] }
    west_charger_entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_west_charger_entity_id"] }

    return false unless rav4_entity.present? && west_charger_entity.present?

    rav4_entity["state"] == "garage" && west_charger_entity["state"] == "not_connected"
  end

  def self.package_present?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_package_box_entity_id"] }

    return false unless entity.present?

    entity["state"] == "on"
  end

  def self.unavailable_door_sensors
    out = []

    Timeframe::Application.config.local["exterior_door_sensors"].concat(
      Timeframe::Application.config.local["exterior_door_locks"]
    ).each do |entity_id|
      if HomeAssistantHome.states.find { _1["entity_id"] == entity_id }&.fetch("state") == "unavailable"
        out << entity_id.split(".").last.gsub("_opening", "").humanize
      end
    end

    out.uniq
  end

  def self.open_doors
    out = []

    Timeframe::Application.config.local["exterior_door_sensors"].map do |entity_id|
      if HomeAssistantHome.states.find { _1["entity_id"] == entity_id }&.fetch("state") == "on"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out
  end

  def self.unlocked_doors
    out = []

    Timeframe::Application.config.local["exterior_door_locks"].map do |entity_id|
      if HomeAssistantHome.states.find { _1["entity_id"] == entity_id }&.fetch("state") == "unlocked"
        out << entity_id.split(".").last.split("_door").first.humanize
      end
    end

    out
  end
end

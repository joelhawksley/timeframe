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

    return true unless entity.present?

    entity["state"].to_i > 10
  end

  def self.garage_door_open?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_entity_id"] }
    entity_2 = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"] }

    return false unless entity.present? && entity_2.present?

    entity["state"] == "open" || entity_2["state"] == "open"
  end

  def self.package_present?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_package_box_entity_id"] }

    return false unless entity.present?

    entity["state"] == "on"
  end
end

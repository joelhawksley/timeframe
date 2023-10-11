class HomeAssistantHome
  def self.fetch
    response = HTTParty.get(
      "http://homeassistant.local:8123/api/states",
      headers: {
        "Authorization": "Bearer #{Timeframe::Application.config.local["home_assistant_token"]}",
        "content-type": "application/json",
      }
    ).body

    Value.upsert({ key: "home_assistant", value:
      {
        states: JSON.parse(response),
        last_fetched_at: Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"]).to_s
      }
    }, unique_by: :key)
  end

  def self.states
    Value.find_or_create_by(key: "home_assistant").value["states"] || []
  end

  def self.healthy?
    return false unless last_fetched_at

    DateTime.parse(last_fetched_at) > DateTime.now - 1.minute
  end

  # :nocov:
  def self.last_fetched_at
    Value.find_or_create_by(key: "home_assistant").value["last_fetched_at"]
  end
  # :nocov:

  def self.garage_door_open?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_garage_door_entity_id"] }

    return false unless entity.present?

    entity["state"] != "closed"
  end

  def self.package_present?
    entity = states.find { _1["entity_id"] == Timeframe::Application.config.local["home_assistant_package_box_entity_id"] }

    return false unless entity.present?

    entity["state"] == "on"
  end
end

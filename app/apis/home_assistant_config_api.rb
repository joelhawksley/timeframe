class HomeAssistantConfigApi < Api
  def initialize(config = Timeframe::Application.config.local)
    @config = config
  end

  def url
    "#{home_assistant_base_url}/api/config"
  end

  def headers
    {
      Authorization: "Bearer #{@config["home_assistant_token"]}",
      "content-type": "application/json"
    }
  end

  def latitude
    data[:latitude]&.to_s
  end

  def longitude
    data[:longitude]&.to_s
  end

  def time_zone
    data[:time_zone]
  end

  def unit_system
    data[:unit_system] || {}
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
end

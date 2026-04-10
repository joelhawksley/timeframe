# frozen_string_literal: true

class TimeframeConfig < Anyway::Config
  config_name :timeframe
  coerce_types temperature_unit: :string

  attr_config home_assistant_token: nil,
    home_assistant_url: "http://homeassistant.local:8123",
    speed_unit: "mph",
    precipitation_unit: "in",
    temperature_unit: "F"

  # Support Home Assistant add-on SUPERVISOR_TOKEN
  on_load do
    if ENV["SUPERVISOR_TOKEN"].present? && home_assistant_token.nil?
      self.home_assistant_token = ENV["SUPERVISOR_TOKEN"]
      self.home_assistant_url = "http://supervisor/core"
    end

    if ENV["SUPERVISOR_TOKEN"].present? && File.exist?("/data/options.json")
      options = JSON.parse(File.read("/data/options.json"))
      self.speed_unit = options["speed_unit"] if options["speed_unit"]
      self.precipitation_unit = options["precipitation_unit"] if options["precipitation_unit"]
      self.temperature_unit = options["temperature_unit"] if options["temperature_unit"]
    end
  end

  def home_assistant?
    home_assistant_token.present?
  end
end

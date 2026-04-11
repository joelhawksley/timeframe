# frozen_string_literal: true

require "test_helper"

class TimeframeConfigTest < Minitest::Test
  def test_defaults
    config = TimeframeConfig.new
    assert_equal "mph", config.speed_unit
    assert_equal "in", config.precipitation_unit
    assert_equal "F", config.temperature_unit
    assert_equal "http://homeassistant.local:8123", config.home_assistant_url
  end

  def test_overrides
    config = TimeframeConfig.new(speed_unit: "kph", temperature_unit: "C", precipitation_unit: "mm")
    assert_equal "kph", config.speed_unit
    assert_equal "C", config.temperature_unit
    assert_equal "mm", config.precipitation_unit
  end

  def test_supervisor_token_sets_home_assistant
    ENV["SUPERVISOR_TOKEN"] = "test_token"
    config = TimeframeConfig.new(home_assistant_token: nil)
    assert_equal "test_token", config.home_assistant_token
    assert_equal "http://supervisor/core", config.home_assistant_url
  ensure
    ENV.delete("SUPERVISOR_TOKEN")
  end
end

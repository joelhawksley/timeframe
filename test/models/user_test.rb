# frozen_string_literal: true

require "test_helper"

class UserTest < Minitest::Test
  def test_hardcoded_tz
    assert_equal(User.new.tz, "America/Denver")
  end

  def test_alerts_empty_state
    assert_equal([], User.new(weather: {}).alerts)
  end

  def test_alerts_with_error_message
    assert_equal(["foo"], User.new(weather: {}, error_messages: ["foo"]).alerts)
  end

  def test_alerts_with_weather_alert
    assert_equal(["bar"], User.new(weather: {alerts: [{title: "bar"}]}).alerts)
  end

  def test_alerts_with_weather_alert_and_error_message
    assert_equal(
      ["foo", "bar"],
      User.new(weather: {alerts: [{title: "bar"}]}, error_messages: ["foo"]).alerts
    )
  end
end

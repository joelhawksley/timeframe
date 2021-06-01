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

  def test_calendar_events_single_event
    start_i = 1621288800
    end_i = 1621292400

    events = [
      {
        start_i: start_i, # 4pm
        end_i: end_i # 5pm
      }
    ]

    user = User.new(calendar_events: events)

    result = user.calendar_events_for(start_i, end_i)

    assert_equal(1, result.length)
    assert_equal("4 - 5p", result[0]["time"])
  end

  def test_calendar_events_exclusion
    excluded_start_i = 1621281700
    excluded_end_i = 1621288700

    included_start_i = 1621288800
    included_end_i = 1621292400

    events = [
      {
        start_i: excluded_start_i, # 4pm
        end_i: excluded_end_i # 5pm
      },
      {
        start_i: included_start_i, # 4pm
        end_i: included_end_i # 5pm
      }
    ]

    user = User.new(calendar_events: events)

    result = user.calendar_events_for(included_start_i, included_end_i)

    assert_equal(1, result.length)
    assert_equal(included_start_i, result[0]["start_i"])
  end
end

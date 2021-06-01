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

  def test_render_json_payload_empty
    result = User.new.render_json_payload(DateTime.new(2001, 2, 3, 4, 5, 6))

    assert_equal("Friday at 9:05 PM", result[:timestamp])
    assert_equal({}, result[:yearly_events])
    assert_equal(4, result[:day_groups].length)
    assert_equal([], result[:emails])
  end

  def test_yearly_events_empty_case
    assert_equal({}, User.new.yearly_events)
  end

  def test_yearly_events
    yearly_event = {
      "end"=>{"date"=>"2021-06-03"},
      "end_i"=>1622699999,
      "start_i"=>1622613600,
      "start"=>{"date"=>"2021-06-02"},
      "summary"=>"Len Inderhees (62)",
      "calendar"=>"Birthdays"
    }

    result = User.new(calendar_events: [yearly_event]).yearly_events(Time.new(2021,6,1))

    assert_equal([6], result.keys)
    assert_equal("Len Inderhees (62)", result[6][0]["summary"])
  end

  def test_yearly_events_excludes_non_birthday
    yearly_event = {
      "end"=>{"date"=>"2021-06-03"},
      "end_i"=>1622699999,
      "start_i"=>1622613600,
      "start"=>{"date"=>"2021-06-02"},
      "summary"=>"Len Inderhees (62)",
      "calendar"=>"Foo"
    }

    result = User.new(calendar_events: [yearly_event]).yearly_events(Time.new(2021,6,1))

    refute result.present?
  end
end

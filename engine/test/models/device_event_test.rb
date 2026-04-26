# frozen_string_literal: true

require "test_helper"

class DeviceEventTest < Minitest::Test
  def test_assigns_time
    event = DeviceEvent.new(
      starts_at: 1675123200,
      ends_at: 1675126800,
      summary: "foo",
      timezone: "America/Chicago"
    )

    assert_equal("6 - 7p", event.time)
  end

  def test_assigns_time_from_datetime
    event = DeviceEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo",
      timezone: "America/Chicago"
    )

    assert_equal("6 - 7p", event.time)
  end

  def test_assigns_time_from_string
    event = DeviceEvent.new(
      starts_at: "2023-08-16T11:30:00.000-06:00",
      ends_at: "2023-08-16T12:30:00.000-06:00",
      summary: "foo",
      timezone: "America/Chicago"
    )

    assert_equal("12:30 - 1:30p", event.time)
  end

  def test_sets_multi_day
    event = DeviceEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo"
    )

    assert_equal(true, event.multi_day?)
  end

  def test_multi_day_time_change
    event = DeviceEvent.new(
      starts_at: 1762063200,
      ends_at: 1762153200,
      summary: "foo",
      timezone: "America/Chicago"
    )

    assert_equal(false, event.multi_day?)
  end

  def test_sets_counter
    event = DeviceEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo",
      description: (Date.today.year - 2).to_s
    )

    assert_equal("foo (2)", event.summary)
  end

  def test_daily_true
    event = DeviceEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: "foo"
    )

    assert(event.daily?)
  end

  def test_daily_false
    event = DeviceEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_daily_same_start_end
    event = DeviceEvent.new(
      starts_at: 1675123200,
      ends_at: 1675123200,
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_daily_24h_non_midnight
    event = DeviceEvent.new(
      starts_at: 1698516000,
      ends_at: 1698602400,
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_start_only
    start = 1621288800 # 5pm Central
    finish = 1621288800

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("5p", event.time)
  end

  def test_start_only_minutes
    start = 1621288860 # 5:01pm Central
    finish = 1621288860

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("5:01p", event.time)
  end

  def test_one_hour_event_in_afternoon_at_top_of_hour
    start = 1621288800 # 5pm Central
    finish = 1621292400 # 6pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("5 - 6p", event.time)
  end

  def test_one_hour_event_in_afternoon_at_minute_past_hour
    start = 1621288860 # 5:01pm Central
    finish = 1621292460 # 6:01pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("5:01 - 6:01p", event.time)
  end

  def test_event_with_same_start_and_end_at_top_of_hour
    start = 1621288800 # 5pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: start, summary: "foo", timezone: "America/Chicago")

    assert_equal("5p", event.time)
  end

  def test_event_with_same_start_and_end_at_minute_past
    start = 1621288860 # 5:01pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: start, summary: "foo", timezone: "America/Chicago")

    assert_equal("5:01p", event.time)
  end

  def test_event_morning_to_afternoon
    start = 1621260000 # 9am Central
    finish = 1621288800 # 5pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("9a - 5p", event.time)
  end

  def test_event_morning_to_afternoon_off_minute
    start = 1621260060 # 9:01am Central
    finish = 1621288860 # 5:01pm Central

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("9:01a - 5:01p", event.time)
  end

  def test_event_different_days_off_by_minutes
    start = 1621220000 # 9:53pm Central 5/16/21
    finish = 1621288800 # 5pm Central 5/17

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("Su 9:53p - M 5p", event.time)
  end

  def test_event_different_days
    start = 1621216820 # 9pm Central 5/16/21
    finish = 1621288800 # 5pm Central 5/17

    event = DeviceEvent.new(starts_at: start, ends_at: finish, summary: "foo", timezone: "America/Chicago")

    assert_equal("Su 9p - M 5p", event.time)
  end

  def test_event_over_time_change
    event = DeviceEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "foo")

    assert(event.daily?)
  end

  def test_strips_emoji
    event = DeviceEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "✨ foo")

    assert_equal("foo", event.summary)
  end

  def test_does_not_strip_things_we_should_keep
    event = DeviceEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "foo bar / \\ ° - _ & : + , ()@ <> '’#")

    assert_equal("foo bar / \\ ° - _ & : + , ()@ <> '’#", event.summary)
  end

  def test_strips_non_ascii
    event = DeviceEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: " ‍ meeting")

    assert_equal("meeting", event.summary)
  end

  def test_daily_summary_count
    event = DeviceEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: "foo"
    )

    assert_equal(event.summary(DateTime.new(2023, 1, 24)), "foo (2/2)")
  end

  def test_omit_if_blank
    event = DeviceEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: ""
    )

    assert(event.omit?)
  end
end

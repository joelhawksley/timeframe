# frozen_string_literal: true

require "test_helper"

class CalendarEventTest < Minitest::Test
  def test_age_in_future
    result = CalendarEvent.for_duration(date: Date.today + 10.weeks + 1.day)
    assert_equal("10w", result.summary)
  end

  def test_for_duration
    result = CalendarEvent.for_duration(date: Date.today - 8.days)

    assert_equal("1w", result.summary)
  end

  def test_for_duration_weeks_days
    result = CalendarEvent.for_duration(date: Date.today - 9.days)

    assert_equal("1w1d", result.summary)
  end

  def test_for_duration_less_than_one_week
    result = CalendarEvent.for_duration(date: Date.today - 7.days)

    assert_equal("6d", result.summary)
  end

  def test_for_duration_works_in_evening
    result = CalendarEvent.for_duration(date: Date.new(2023, 8, 20), today: Date.new(2023, 8, 27))

    assert_equal(27, result.starts_at.day)
    assert_equal(28, result.ends_at.day)
  end

  def test_for_duration_1_yr
    result = CalendarEvent.for_duration(date: Date.new(2023, 7, 11), today: Date.new(2024, 7, 11))

    assert_equal("12m", result.summary)
  end

  def test_for_duration_18_mos
    result = CalendarEvent.for_duration(date: Date.new(2023, 7, 11), today: Date.new(2025, 1, 11))

    assert_equal("18m", result.summary)
  end

  def test_for_duration_24m_less_day
    result = CalendarEvent.for_duration(date: Date.new(2023, 7, 11), today: Date.new(2025, 7, 10))

    assert_equal("24m", result.summary)
  end

  def test_for_duration_36_mos
    result = CalendarEvent.for_duration(date: Date.new(2023, 7, 11), today: Date.new(2026, 7, 11))

    assert_equal("3y", result.summary)
  end

  def test_for_duration_36_mos_1_day
    result = CalendarEvent.for_duration(date: Date.new(2023, 7, 11), today: Date.new(2026, 7, 12))

    assert_equal("3y1d", result.summary)
  end

  def test_assigns_time
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675126800,
      summary: "foo"
    )

    assert_equal("5 - 6p", event.time)
  end

  def test_assigns_time_from_datetime
    event = CalendarEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo"
    )

    assert_equal("5 - 6p", event.time)
  end

  def test_assigns_time_from_string
    event = CalendarEvent.new(
      starts_at: "2023-08-16T11:30:00.000-06:00",
      ends_at: "2023-08-16T12:30:00.000-06:00",
      summary: "foo"
    )

    assert_equal("11:30a - 12:30p", event.time)
  end

  def test_sets_multi_day
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo"
    )

    assert_equal(true, event.multi_day?)
  end

  def test_sets_counter
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo",
      description: (Date.today.year - 2).to_s
    )

    assert_equal("foo (2)", event.summary)
  end

  def test_daily_true
    event = CalendarEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: "foo"
    )

    assert(event.daily?)
  end

  def test_daily_false
    event = CalendarEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_daily_same_start_end
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675123200,
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_daily_24h_non_midnight
    event = CalendarEvent.new(
      starts_at: 1698516000,
      ends_at: 1698602400,
      summary: "foo"
    )

    refute(event.daily?)
  end

  def test_start_only
    start = 1621288800 # 4pm
    finish = 1621288800

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("4p", event.time)
  end

  def test_start_only_minutes
    start = 1621288860 # 4pm
    finish = 1621288860

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("4:01p", event.time)
  end

  def test_one_hour_event_in_afternoon_at_top_of_hour
    start = 1621288800 # 4pm
    finish = 1621292400 # 5pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("4 - 5p", event.time)
  end

  def test_one_hour_event_in_afternoon_at_minute_past_hour
    start = 1621288860 # 4:01pm
    finish = 1621292460 # 5:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("4:01 - 5:01p", event.time)
  end

  def test_event_with_same_start_and_end_at_top_of_hour
    start = 1621288800 # 4pm

    event = CalendarEvent.new(starts_at: start, ends_at: start, summary: "foo")

    assert_equal("4p", event.time)
  end

  def test_event_with_same_start_and_end_at_minute_past
    start = 1621288860 # 4:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: start, summary: "foo")

    assert_equal("4:01p", event.time)
  end

  def test_event_morning_to_afternoon
    start = 1621260000 # 8am
    finish = 1621288800 # 4pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("8a - 4p", event.time)
  end

  def test_event_morning_to_afternoon_off_minute
    start = 1621260060 # 8:01am
    finish = 1621288860 # 4:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("8:01a - 4:01p", event.time)
  end

  def test_event_different_days_off_by_minutes
    start = 1621220000 # 8:53am 5/16/21
    finish = 1621288800 # 4pm 5/17

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("Sun 8:53p -<br />Mon 4p", event.time)
  end

  def test_event_different_days
    start = 1621216820 # 8am 5/16/21
    finish = 1621288800 # 4pm 5/17

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo")

    assert_equal("Sun 8p -<br />Mon 4p", event.time)
  end

  def test_event_over_time_change
    event = CalendarEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "foo")

    assert(event.daily?)
  end

  def test_strips_emoji
    event = CalendarEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "✨ foo")

    assert_equal("foo", event.summary)
  end

  def test_does_not_strip_things_we_should_keep
    event = CalendarEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: "foo bar / \\ ° - _ & : + , ()@ <> '’#")

    assert_equal("foo bar / \\ ° - _ & : + , ()@ <> '’#", event.summary)
  end

  def test_strips_non_ascii
    event = CalendarEvent.new(starts_at: "2023-11-01", ends_at: "2023-11-08", summary: " ‍ meeting")

    assert_equal("meeting", event.summary)
  end

  def test_daily_summary_count
    event = CalendarEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: "foo"
    )

    assert_equal(event.summary(DateTime.new(2023, 1, 24)), "foo (2/2)")
  end

  def test_omit_if_blank
    event = CalendarEvent.new(
      starts_at: DateTime.new(2023, 1, 23),
      ends_at: DateTime.new(2023, 1, 25),
      summary: ""
    )

    assert(event.omit?)
  end
end

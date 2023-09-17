# frozen_string_literal: true

require "test_helper"

class CalendarEventTest < Minitest::Test
  def test_assigns_time
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675126800,
      summary: "foo",
    ).to_h

    assert_equal("5 - 6p", event[:time])
  end

  def test_assigns_time_from_datetime
    event = CalendarEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo",
    ).to_h

    assert_equal("5 - 6p", event[:time])
  end

  def test_assigns_time_from_string
    event = CalendarEvent.new(
      starts_at: "2023-08-16T11:30:00.000-06:00",
      ends_at: "2023-08-16T12:30:00.000-06:00",
      summary: "foo",
    ).to_h

    assert_equal("11:30a - 12:30p", event[:time])
  end

  def test_sets_multi_day
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo",
    ).to_h

    assert_equal(true, event[:multi_day])
  end

  def test_sets_counter
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675209601,
      summary: "foo",
      description: (Date.today.year - 2).to_s,
    ).to_h

    assert_equal("foo (2)", event[:summary])
  end

  def test_daily_true
    event = CalendarEvent.new(
      starts_at: DateTime.new(2023,1,23),
      ends_at: DateTime.new(2023,1,25),
      summary: "foo",
    ).to_h

    assert(event[:daily])
  end

  def test_daily_false
    event = CalendarEvent.new(
      starts_at: Time.at(1675123200),
      ends_at: Time.at(1675126800),
      summary: "foo",
    ).to_h

    refute(event[:daily])
  end

  def test_daily_same_start_end
    event = CalendarEvent.new(
      starts_at: 1675123200,
      ends_at: 1675123200,
      summary: "foo",
    ).to_h

    refute(event[:daily])
  end

  def test_start_only
    start = 1621288800 # 4pm
    finish = 1621288800

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("4p", event[:time])
  end

  def test_start_only_minutes
    start = 1621288860 # 4pm
    finish = 1621288860

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("4:01p", event[:time])
  end

  def test_one_hour_event_in_afternoon_at_top_of_hour
    start = 1621288800 # 4pm
    finish = 1621292400 # 5pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("4 - 5p", event[:time])
  end

  def test_one_hour_event_in_afternoon_at_minute_past_hour
    start = 1621288860 # 4:01pm
    finish = 1621292460 # 5:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("4:01 - 5:01p", event[:time])
  end

  def test_event_with_same_start_and_end_at_top_of_hour
    start = 1621288800 # 4pm

    event = CalendarEvent.new(starts_at: start, ends_at: start, summary: "foo").to_h

    assert_equal("4p", event[:time])
  end

  def test_event_with_same_start_and_end_at_minute_past
    start = 1621288860 # 4:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: start, summary: "foo").to_h

    assert_equal("4:01p", event[:time])
  end

  def test_event_morning_to_afternoon
    start = 1621260000 # 8am
    finish = 1621288800 # 4pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("8a - 4p", event[:time])
  end

  def test_event_morning_to_afternoon_off_minute
    start = 1621260060 # 8:01am
    finish = 1621288860 # 4:01pm

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("8:01a - 4:01p", event[:time])
  end

  def test_event_different_days_off_by_minutes
    start = 1621220000 # 8:53am 5/16/21
    finish = 1621288800 # 4pm 5/17

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("Sun 8:53p -<br />Mon 4p", event[:time])
  end

  def test_event_different_days
    start = 1621216820 # 8am 5/16/21
    finish = 1621288800 # 4pm 5/17

    event = CalendarEvent.new(starts_at: start, ends_at: finish, summary: "foo").to_h

    assert_equal("Sun 8p -<br />Mon 4p", event[:time])
  end
end

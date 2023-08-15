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

    assert_equal("5 - 6p", event[:time])
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
end

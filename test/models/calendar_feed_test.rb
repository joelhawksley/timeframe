# frozen_string_literal: true

require "test_helper"

class CalendarFeedTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_age_in_future
    result = CalendarFeed.new.baby_age_event(Date.today + 10.weeks + 1.day)
    assert_equal("10w", result.summary)
  end

  def test_baby_age_event
    result = CalendarFeed.new.baby_age_event(Date.today - 8.days)

    assert_equal("1w", result.summary)
  end

  def test_baby_age_event_weeks_days
    result = CalendarFeed.new.baby_age_event(Date.today - 9.days)

    assert_equal("1w1d", result.summary)
  end

  def test_baby_age_event_less_than_one_week
    result = CalendarFeed.new.baby_age_event(Date.today - 7.days)

    assert_equal("6d", result.summary)
  end

  def test_baby_age_event_works_in_evening
    travel_to DateTime.new(2023, 8, 27, 20, 20, 0, "-0600") do
      result = CalendarFeed.new.baby_age_event(Date.today - 7.days)

      assert_equal(27, result.starts_at.day)
      assert_equal(28, result.ends_at.day)
    end
  end

  def test_baby_age_event_1_yr
    travel_to DateTime.new(2024, 7, 11, 8, 0, 0, "-0600") do
      result = CalendarFeed.new.baby_age_event(Date.new(2023, 7, 11))

      assert_equal("12m", result.summary)
    end
  end

  def test_baby_age_event_18_mos
    travel_to DateTime.new(2025, 1, 11, 8, 0, 0, "-0600") do
      result = CalendarFeed.new.baby_age_event(Date.new(2023, 7, 11))

      assert_equal("18m", result.summary)
    end
  end

  def test_baby_age_event_36_mos
    travel_to DateTime.new(2026, 7, 11, 8, 0, 0, "-0600") do
      result = CalendarFeed.new.baby_age_event(Date.new(2023, 7, 11))

      assert_equal("3y", result.summary)
    end
  end

  def test_baby_age_event_36_mos_1_day
    travel_to DateTime.new(2026, 7, 12, 8, 0, 0, "-0600") do
      result = CalendarFeed.new.baby_age_event(Date.new(2023, 7, 11))

      assert_equal("3y1d", result.summary)
    end
  end

  # CalendarEvents coming from the DB look different than those
  # constructed on the fly. DB events have string keys, for example.
  # This is not ideal and we should probably move to a standard value
  # object that has a consistent API.
  def test_events_for_stringified_key_from_db
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "+"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)
    end
  end

  def test_events_for_duplicate_plus
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "+"
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "J"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      result = CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)
      events = result[:periodic].select { _1.id == "foo" }

      assert(events.length == 1)
      assert(events[0].icon == "+")
    end
  end

  def test_events_for_duplicate_same_icon
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "J"
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "J"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      result = CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)
      events = result[:periodic].select { _1.id == "foo" }

      assert(events.length == 1)
      assert(events[0].icon == "J")
    end
  end

  def test_events_for_duplicate_different_icon
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "C"
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 23, 0, 0, "-0600"),
        summary: "dupe",
        icon: "J"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      result = CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)
      events = result[:periodic].select { _1.id == "foo" }

      assert(events.length == 1)
      assert(events[0].icon == "C")
    end
  end

  # Ran into this bug upgrading to Rails 7.1. Momentary events were not
  # returned due to a bug in range overlap comparison
  def test_filtering_moments
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        summary: "momentary events should not be filtered out!",
        icon: "C"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:periodic].length == 1)
    end
  end

  def test_filtering_daily
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 0, 0, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 28, 0, 0, 0, "-0600"),
        summary: "daily events should not be filtered out!",
        icon: "C"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:daily].length == 1)

      start_time_utc = DateTime.new(2023, 8, 28, 20, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 29, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:daily].length == 0)
    end
  end

  def test_filtering_multi_day_periodic_events
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 29, 22, 20, 0, "-0600"),
        summary: "multi-day periodic events should not be filtered out!",
        icon: "C"
      )
    ]

    travel_to DateTime.new(2023, 8, 28, 22, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 22, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:periodic].length == 1)
    end
  end

  def test_filtering_private_events
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 15, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        summary: "timeframe-private"
      ),
      CalendarEvent.new(
        id: "bar",
        starts_at: DateTime.new(2023, 8, 27, 15, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        summary: "doctor",
        description: "timeframe-private"
      ),
      CalendarEvent.new(
        id: "bar",
        starts_at: DateTime.new(2023, 8, 27, 0, 0, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 28, 0, 0, 0, "-0600"),
        summary: "prep",
        description: "timeframe-private"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 17, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 0, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events, true)[:periodic].length == 0)
    end
  end

  def test_excludes_omit
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 15, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        summary: "Hide me!",
        description: "timeframe-omit"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 17, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 0, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:periodic].length == 0)
    end
  end

  def test_excludes_omit_with_other_details
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023, 8, 27, 15, 20, 0, "-0600"),
        ends_at: DateTime.new(2023, 8, 27, 20, 20, 0, "-0600"),
        summary: "Hide me!",
        description: "1995\ntimeframe-omit"
      )
    ]

    travel_to DateTime.new(2023, 8, 27, 17, 20, 0, "-0600") do
      start_time_utc = DateTime.new(2023, 8, 27, 0, 20, 0, "-0600").utc.to_time
      end_time_utc = DateTime.new(2023, 8, 28, 0, 0, 0, "-0600").utc.to_time

      assert(CalendarFeed.new.events_for(start_time_utc, end_time_utc, calendar_events)[:periodic].length == 0)
    end
  end
end

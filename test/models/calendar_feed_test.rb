# frozen_string_literal: true

require "test_helper"

class CalendarFeedTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

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
      events = result[:periodic].select { it.id == "foo" }

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
      events = result[:periodic].select { it.id == "foo" }

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
      events = result[:periodic].select { it.id == "foo" }

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

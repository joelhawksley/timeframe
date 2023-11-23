# frozen_string_literal: true

require "test_helper"

class CalendarFeedTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_baby_age_event
    result = CalendarFeed.baby_age_event(Date.today - 7.days)

    assert_equal("1w", result.to_h[:summary])
  end

  def test_baby_age_event_weeks_days
    result = CalendarFeed.baby_age_event(Date.today - 8.days)

    assert_equal("1w1d", result.to_h[:summary])
  end

  def test_baby_age_event_less_than_one_week
    result = CalendarFeed.baby_age_event(Date.today - 6.days)

    assert_equal("6d", result.to_h[:summary])
  end

  def test_baby_age_event_works_in_evening
    travel_to DateTime.new(2023,8,27,20,20,0,"-0600") do
      result = CalendarFeed.baby_age_event(Date.today - 7.days)

      assert_equal(27, result.to_h[:starts_at].day)
      assert_equal(28, result.to_h[:ends_at].day)
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
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "+"
      ).to_h.stringify_keys
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        CalendarFeed.events_for(start_time_utc, end_time_utc)
      end
    end
  end

  def test_events_for_duplicate_plus
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "+"
      ).to_h,
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      ).to_h
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarFeed.events_for(start_time_utc, end_time_utc)
        events = result[:periodic].select { _1[:id] == "foo" }

        assert(events.length == 1)
        assert(events[0][:letter] == "+")
      end
    end
  end

  def test_events_for_duplicate_same_letter
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      ).to_h,
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      ).to_h
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarFeed.events_for(start_time_utc, end_time_utc)
        events = result[:periodic].select { _1[:id] == "foo" }

        assert(events.length == 1)
        assert(events[0][:letter] == "J")
      end
    end
  end

  def test_events_for_duplicate_different_letter
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "C"
      ).to_h,
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      ).to_h
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarFeed.events_for(start_time_utc, end_time_utc)
        events = result[:periodic].select { _1[:id] == "foo" }

        assert(events.length == 1)
        assert(events[0][:letter] == "C")
      end
    end
  end

  # Ran into this bug upgrading to Rails 7.1. Momentary events were not
  # returned due to a bug in range overlap comparison
  def test_filtering_moments
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        summary: "momentary events should not be filtered out!",
        letter: "C"
      ).to_h
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        assert(CalendarFeed.events_for(start_time_utc, end_time_utc)[:periodic].length == 1)
      end
    end
  end

  def test_filtering_daily
    calendar_events = [
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,0,0,0,"-0600"),
        ends_at: DateTime.new(2023,8,28,0,0,0,"-0600"),
        summary: "daily events should not be filtered out!",
        letter: "C"
      ).to_h
    ]

    CalendarFeed.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        assert(CalendarFeed.events_for(start_time_utc, end_time_utc)[:daily].length == 2)

        start_time_utc = DateTime.new(2023,8,28,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,29,0,0,0,"-0600").utc.to_time
        assert(CalendarFeed.events_for(start_time_utc, end_time_utc)[:daily].length == 0)
      end
    end
  end
end

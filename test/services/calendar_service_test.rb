# frozen_string_literal: true

require "test_helper"

class CalendarServiceTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_baby_age_event
    result = CalendarService.baby_age_event(Date.today - 7.days)

    assert_equal("1w", result.to_h[:summary])
  end

  def test_baby_age_event_weeks_days
    result = CalendarService.baby_age_event(Date.today - 8.days)

    assert_equal("1w1d", result.to_h[:summary])
  end

  def test_baby_age_event_less_than_one_week
    result = CalendarService.baby_age_event(Date.today - 6.days)

    assert_equal("6d", result.to_h[:summary])
  end

  def test_baby_age_event_works_in_evening
    travel_to DateTime.new(2023,8,27,20,20,0,"-0600") do
      result = CalendarService.baby_age_event(Date.today - 7.days)

      assert_equal(27, result.to_h[:starts_at].day)
      assert_equal(28, result.to_h[:ends_at].day)
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
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      )
    ]

    CalendarService.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarService.events_for(start_time_utc, end_time_utc)
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
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      )
    ]

    CalendarService.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarService.events_for(start_time_utc, end_time_utc)
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
      ),
      CalendarEvent.new(
        id: "foo",
        starts_at: DateTime.new(2023,8,27,20,20,0,"-0600"),
        ends_at: DateTime.new(2023,8,27,23,0,0,"-0600"),
        summary: "dupe",
        letter: "J"
      )
    ]

    CalendarService.stub :calendar_events, calendar_events do
      travel_to DateTime.new(2023,8,27,22,20,0,"-0600") do
        start_time_utc = DateTime.new(2023,8,27,20,20,0,"-0600").utc.to_time
        end_time_utc = DateTime.new(2023,8,28,0,0,0,"-0600").utc.to_time

        result = CalendarService.events_for(start_time_utc, end_time_utc)
        events = result[:periodic].select { _1[:id] == "foo" }

        assert(events.length == 1)
        assert(events[0][:letter] == "C")
      end
    end
  end
end

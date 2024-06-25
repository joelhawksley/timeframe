# frozen_string_literal: true

require "test_helper"

class DisplayContenttTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_no_data
    result = DisplayContent.new.call

    assert_nil(result[:current_temperature])
    assert_equal(result[:day_groups].count, 5)
  end

  def test_hide_events_after_cutoff
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      result = DisplayContent.new.call

      assert_equal(result[:day_groups].count, 4)
    end
  end

  def test_hide_events_after_cutoff_if_periodic_extends_to_tomorrow
    travel_time = DateTime.new(2023, 8, 27, 20, 15, 0, "-0600")
    travel_to travel_time do
      api = GoogleCalendarApi.new
      api.stub :healthy?, true do
        api.stub :data, [
          CalendarEvent.new(starts_at: travel_time - 1.hour, ends_at: travel_time + 1.day, summary: "test")
        ] do
          result = DisplayContent.new.call(google_calendar_api: api)

          assert_equal(result[:day_groups].count, 4)
        end
      end
    end
  end
end

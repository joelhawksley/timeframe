# frozen_string_literal: true

require "test_helper"

class HomeAssistantCalendarApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_fetch
    VCR.use_cassette(:home_assistant_calendar_states) do
      travel_to DateTime.new(2024, 9, 5, 15, 15, 0, "-0600") do
        api = HomeAssistantCalendarApi.new
        api.fetch

        assert(api.data.length > 1)
      end
    end
  end

  def test_private_mode
    api = HomeAssistantCalendarApi.new
    assert_equal(false, api.private_mode?)

    data = [
      CalendarEvent.new(
        starts_at: DateTime.new(2024, 9, 5, 12, 0, 0, "-0600"),
        ends_at: DateTime.new(2024, 9, 5, 16, 0, 0, "-0600"),
        summary: "timeframe-private"
      )
    ]

    travel_to DateTime.new(2024, 9, 5, 15, 15, 0, "-0600") do
      api.stub :data, data do
        assert(api.private_mode?)
      end
    end
  end
end

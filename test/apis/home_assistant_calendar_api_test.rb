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
end

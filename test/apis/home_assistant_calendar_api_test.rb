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

  def test_fetch_calendar_icons
    VCR.use_cassette(:home_assistant_calendar_icons) do
      api = HomeAssistantCalendarApi.new
      icons = api.fetch_calendar_icons([{"entity_id" => "calendar.birthdays"}])

      assert_equal("calendar", icons["calendar.birthdays"])
    end
  end

  def test_fetch_calendar_icons_non_200
    api = HomeAssistantCalendarApi.new
    response = Struct.new(:code).new(500)
    HTTParty.stub :get, response do
      icons = api.fetch_calendar_icons([{"entity_id" => "calendar.test"}])
      assert_equal({}, icons)
    end
  end

  def test_fetch_calendar_icons_no_icon
    api = HomeAssistantCalendarApi.new
    response = Struct.new(:code, :parsed_response).new(200, {"attributes" => {}})
    response.define_singleton_method(:dig) { |*keys| {"attributes" => {}}.dig(*keys) }
    HTTParty.stub :get, response do
      icons = api.fetch_calendar_icons([{"entity_id" => "calendar.test"}])
      assert_equal({}, icons)
    end
  end

  def test_fetch_calendar_icons_invalid_icon
    api = HomeAssistantCalendarApi.new
    response = Struct.new(:code, :parsed_response).new(200, {"attributes" => {"icon" => "mdi:nonexistent-icon-xyz"}})
    response.define_singleton_method(:dig) { |*keys| {"attributes" => {"icon" => "mdi:nonexistent-icon-xyz"}}.dig(*keys) }
    HTTParty.stub :get, response do
      icons = api.fetch_calendar_icons([{"entity_id" => "calendar.test"}])
      assert_equal({}, icons)
    end
  end

  def test_fetch_calendars_non_200
    api = HomeAssistantCalendarApi.new
    response = Struct.new(:code, :parsed_response).new(500, nil)
    HTTParty.stub :get, response do
      assert_equal([], api.fetch_calendars)
    end
  end
end

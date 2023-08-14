# frozen_string_literal: true

require "test_helper"

class WeatherKitServiceTest < Minitest::Test
  def test_weather_no_data
    assert_equal({}, WeatherKitService.weather)
  end

  def test_temperature_range_for_no_data
    assert_nil(WeatherKitService.temperature_range_for(Date.today))
  end

  def test_current_temperature_no_data
    assert_nil(WeatherKitService.current_temperature)
  end

  def test_health_no_data?
    assert(WeatherKitService.healthy?)
  end

  def test_calendar_events_no_data
    assert_equal([], WeatherKitService.calendar_events)
  end

  def test_precip_calendar_events_no_data
    assert_equal([], WeatherKitService.precip_calendar_events)
  end
end
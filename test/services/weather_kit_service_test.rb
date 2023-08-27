# frozen_string_literal: true

require "test_helper"
require "active_support/testing/time_helpers"

class WeatherKitServiceTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_weather_no_data
    assert_equal({}, WeatherKitService.weather)
  end

  def test_temperature_range_for_no_data
    assert_nil(WeatherKitService.temperature_range_for(Date.today))
  end

  def test_temperature_range_for_example
    weather = {
      "forecastDaily" => {
        "days" => [
          {
            "forecastStart"=>"2023-08-27T06:00:00Z",
            "temperatureMax"=>30.38,
            "temperatureMin"=>14.47,
          },
          {
            "forecastStart"=>"2023-08-28T06:00:00Z",
            "temperatureMax"=>25.32,
            "temperatureMin"=>15.16,
          }
        ]
      }
    }

    WeatherKitService.stub :weather, weather do
      assert_equal("&#8593;87 &#8595;58", WeatherKitService.temperature_range_for(Date.new(2023,8,27)))
    end
  end

  def test_current_temperature_no_data
    assert_nil(WeatherKitService.current_temperature)
  end

  def test_current_temperature
    weather = {
      "currentWeather" =>
        {
          "temperature" => 30.06
        }
    }

    WeatherKitService.stub :weather, weather do
      assert_equal("86°", WeatherKitService.current_temperature)
    end
  end

  def test_health_no_data
    assert(WeatherKitService.healthy?)
  end

  def test_health_current_data
    WeatherKitService.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023,8,27,15,20,0, "-0600") do
        assert(WeatherKitService.healthy?)
      end
    end
  end

  def test_health_stale_data
    WeatherKitService.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023,8,27,16,20,0,"-0600") do
        refute(WeatherKitService.healthy?)
      end
    end
  end

  def test_calendar_events_no_data
    assert_equal([], WeatherKitService.calendar_events)
  end

  def test_precip_calendar_events_no_data
    assert_equal([], WeatherKitService.precip_calendar_events)
  end
end
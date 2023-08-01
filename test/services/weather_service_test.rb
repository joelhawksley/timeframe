

# frozen_string_literal: true

require "test_helper"

class WeatherServiceTest < Minitest::Test
  def test_icon_for_period
    result = WeatherService.icon_for_period("https://api.weather.gov/icons/land/day/bkn,0?size=small")

    assert_equal(["bkn,0", "clouds-sun"], result)
  end

  def test_icon_for_period_ovc
    result = WeatherService.icon_for_period("https://api.weather.gov/icons/land/day/ovc,12?size=small")

    assert_equal(["ovc,12", "clouds"], result)
  end

  def test_icon_for_unknown
    result = WeatherService.icon_for_period("https://api.weather.gov/icons/land/day/foo,0?size=small")

    assert_equal(["foo,0", "question"], result)
  end

  def test_healthy_false_without_log
    assert_equal(false, WeatherService.healthy?)
  end

  def test_healthy_false_with_old_log
    assert_equal(
      false, 
      WeatherService.healthy?(
        Log.new(
          globalid: 'WeatherService', 
          event: 'call_success', 
          message: "foo", 
          created_at: DateTime.now - 2.hours
        )
      )
    )
  end

  def test_healthy_with_log
    assert_equal(
      true, 
      WeatherService.healthy?(
        Log.new(
          globalid: 'WeatherService', 
          event: 'call_success', 
          message: "foo", 
          created_at: DateTime.now
        )
      )
    )
  end
end
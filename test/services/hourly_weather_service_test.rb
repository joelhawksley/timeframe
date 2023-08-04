# frozen_string_literal: true

require "test_helper"

class HourlyWeatherServiceTest < Minitest::Test
  def test_icon_for_period_fetch
    result = HourlyWeatherService.fetch
  end

  def test_icon_for_period
    result = HourlyWeatherService.icon_for_period("https://api.weather.gov/icons/land/day/bkn,0?size=small")

    assert_equal(["bkn,0", "clouds-sun"], result)
  end

  def test_icon_for_period_ovc
    result = HourlyWeatherService.icon_for_period("https://api.weather.gov/icons/land/day/ovc,12?size=small")

    assert_equal(["ovc,12", "clouds"], result)
  end

  def test_icon_for_unknown
    result = HourlyWeatherService.icon_for_period("https://api.weather.gov/icons/land/day/foo,0?size=small")

    assert_equal(["foo,0", "question"], result)
  end
end
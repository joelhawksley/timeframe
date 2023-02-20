

# frozen_string_literal: true

require "test_helper"

class WeatherServiceTest < Minitest::Test
  def test_icon_for_period
    result = WeatherService.icon_for_period("https://api.weather.gov/icons/land/day/bkn,0?size=small")

    assert_equal(["bkn,0", "fa-solid fa-clouds-sun"], result)
  end

  def test_icon_for_unknown
    result = WeatherService.icon_for_period("https://api.weather.gov/icons/land/day/foo,0?size=small")

    assert_equal(["foo,0", "fa-solid fa-question"], result)
  end
end
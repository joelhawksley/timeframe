# frozen_string_literal: true

require "test_helper"

class WeatherServiceTest < Minitest::Test
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
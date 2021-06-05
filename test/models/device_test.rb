# frozen_string_literal: true

require "test_helper"

class DeviceTest < Minitest::Test
  def test_width
    assert_equal(1600, Device.new(template: "13_calendar_weather").width)
  end

  def test_height
    assert_equal(1200, Device.new(template: "13_calendar_weather").height)
  end
end
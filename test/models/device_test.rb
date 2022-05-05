# frozen_string_literal: true

require "test_helper"
require "capybara/minitest"

class DeviceTest < Minitest::Test
  include Capybara::Minitest::Assertions

  def test_width
    assert_equal(1200, Device.new(template: "13_calendar_weather").width)
  end

  def test_height
    assert_equal(1600, Device.new(template: "13_calendar_weather").height)
  end

  def test_battery_level_default
    assert_equal(100, Device.new.battery_level)
  end

  def test_battery_level_invalid_hash
    assert_equal(100, Device.new(status: {}).battery_level)
  end

  def test_battery_level_valid_hash
    assert_equal(93, Device.new(status: {"Status" => {"Battery" => 93.09}}).battery_level)
  end

  def test_html_renders
    render_device(Device.new(user: User.new, template: "13_calendar_weather"))

    assert_text(100)
  end

  private

  def render_device(device)
    @html = device.html

    Nokogiri::HTML.fragment(@html)
  end

  def page
    Capybara::Node::Simple.new(@html)
  end
end

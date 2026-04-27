# frozen_string_literal: true

require "test_helper"

class DemoDeviceContentTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_returns_all_required_keys
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal "72°", result[:current_temperature]
      assert result[:timestamp].present?
      assert result[:current_time].present?
      assert result[:top_left].is_a?(Array)
      assert result[:top_right].is_a?(Array)
      assert result[:weather_status].is_a?(Array)
      assert result[:now_playing].is_a?(Hash)
      assert result[:day_groups].is_a?(Array)
      assert result[:minutely_weather_minutes].is_a?(Array)
      assert_equal "weather-rainy", result[:minutely_weather_minutes_icon]
      assert result[:minutely_precipitation_bars].is_a?(Array)
      assert_nil result[:attribution]
      assert_equal false, result[:private_mode]
    end
  end

  def test_has_five_day_groups
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal 5, result[:day_groups].count
      assert_equal "Today", result[:day_groups][0][:day_name]
      assert_equal "Tomorrow", result[:day_groups][1][:day_name]
    end
  end

  def test_day_groups_have_required_structure
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      result[:day_groups].each do |day|
        assert day[:day_name].present?
        assert day[:date].is_a?(Date)
        assert day[:daily].is_a?(Array)
        assert day[:periodic].is_a?(Array)
        assert [true, false].include?(day[:show_daily])
      end
    end
  end

  def test_today_has_birthday_with_age
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_daily = result[:day_groups][0][:daily]

      birthday = today_daily.find { |e| e[:summary].include?("Sarah Johnson") }
      assert birthday, "Expected a birthday event"
      assert_equal "cake-variant", birthday[:icon_class]
      assert birthday[:summary].include?("36"), "Expected age 36 in 2026"
    end
  end

  def test_today_has_multi_day_vacation_with_counter
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_daily = result[:day_groups][0][:daily]

      vacation = today_daily.find { |e| e[:summary].include?("Vacation") }
      assert vacation, "Expected a Vacation event"
      assert vacation[:summary].include?("/"), "Expected counter in summary"
    end
  end

  def test_today_has_events_with_locations
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_periodic = result[:day_groups][0][:periodic]

      located = today_periodic.select { |e| e[:location].present? }
      assert located.any?, "Expected events with locations"
    end
  end

  def test_tomorrow_has_wind_event_with_rotation
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      tomorrow_periodic = result[:day_groups][1][:periodic]

      wind = tomorrow_periodic.find { |e| e[:icon_style].present? }
      assert wind, "Expected a wind event with rotation style"
      assert_equal "arrow-up", wind[:icon_class]
    end
  end

  def test_uses_alpha_letter_calendar_icons
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_periodic = result[:day_groups][0][:periodic]

      alpha_j = today_periodic.select { |e| e[:icon_text] == "J" }
      assert alpha_j.any?, "Expected J icon for Joel's calendar events"

      alpha_f = today_periodic.select { |e| e[:icon_text] == "F" }
      assert alpha_f.any?, "Expected F icon for family calendar events"
    end
  end

  def test_top_left_sensors
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal 1, result[:top_left].count
      assert result[:top_left].any? { |s| s[:icon] == "door-open" }
    end
  end

  def test_top_right_bird
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal 1, result[:top_right].count
      assert_equal "bird", result[:top_right][0][:icon]
      assert_equal "Spotted Towhee", result[:top_right][0][:label]
    end
  end

  def test_weather_status_rotated_arrow
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal 1, result[:weather_status].count
      assert_equal "arrow-up", result[:weather_status][0][:icon]
      assert_equal "12", result[:weather_status][0][:label]
      assert_equal 45, result[:weather_status][0][:rotation]
    end
  end

  def test_now_playing
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal "Tycho", result[:now_playing][:artist]
      assert_equal "A Walk", result[:now_playing][:track]
    end
  end

  def test_minutely_weather_data
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")

      assert_equal 60, result[:minutely_weather_minutes].count
      result[:minutely_weather_minutes].each do |minute|
        assert minute.key?(:precipitationChance)
        assert minute.key?(:precipitationIntensity)
      end
      assert_equal 60, result[:minutely_precipitation_bars].count
    end
  end

  def test_today_has_long_event_name
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_periodic = result[:day_groups][0][:periodic]

      long = today_periodic.find { |e| e[:summary].length > 30 }
      assert long, "Expected a long event name for truncation demo"
    end
  end

  def test_today_has_past_midnight_event
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      today_periodic = result[:day_groups][0][:periodic]

      past_midnight = today_periodic.find { |e| e[:time_html].include?(" - ") }
      assert past_midnight, "Expected an event spanning past midnight"
    end
  end

  def test_day_3_has_overlapping_events
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago")
      day3_periodic = result[:day_groups][2][:periodic]

      lunch = day3_periodic.find { |e| e[:summary].include?("Lunch") }
      call = day3_periodic.find { |e| e[:summary].include?("Call") }
      assert lunch && call, "Expected overlapping Lunch and Call events"
    end
  end

  def test_three_day_mode_limits_days_and_excludes_wind
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago", days: 3, include_precip: false, include_wind: false)
      assert_equal 3, result[:day_groups].length
      day1_periodic = result[:day_groups][1][:periodic]
      wind_event = day1_periodic.find { |e| e[:summary]&.include?("Gusts") }
      assert_nil wind_event, "Wind events should be excluded"
    end
  end

  def test_use_day_names_option
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago", use_day_names: true)

      assert_equal "Thursday", result[:day_groups][0][:day_name]
      assert_equal "Friday", result[:day_groups][1][:day_name]
    end
  end

  def test_weather_row_extracts_weather_events
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago", weather_row: true)

      today = result[:day_groups][0]
      assert today[:weather_row].is_a?(Array)
      assert today[:weather_row].any?, "Expected weather row items"
      assert today[:periodic].none? { |e| e[:icon_class]&.start_with?("weather-") && e[:summary]&.end_with?("°") && e[:time_html] == e[:start_time] }
    end
  end

  def test_start_time_only_flag
    travel_to DateTime.new(2026, 3, 19, 8, 0, 0, "-0500") do
      result = DemoDeviceContent.new.call(timezone: "America/Chicago", start_time_only: true)

      assert result[:start_time_only]
    end
  end
end

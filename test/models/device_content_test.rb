# frozen_string_literal: true

require "test_helper"

class DeviceContenttTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_no_data
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      result = DeviceContent.new.call(home_assistant_api: new_test_api)

      assert_nil(result[:current_temperature])
      assert_equal(result[:day_groups].count, 5)
    end
  end

  def test_hide_events_after_cutoff
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      result = DeviceContent.new.call(home_assistant_api: new_test_api)

      assert_equal(result[:day_groups].count, 4)
    end
  end

  def test_hide_events_after_cutoff_if_periodic_extends_to_tomorrow
    travel_time = DateTime.new(2023, 8, 27, 20, 15, 0, "-0600")
    travel_to travel_time do
      api = new_test_api
      api.stub :calendars_healthy?, false do
        api.stub :calendar_events, [
          DeviceEvent.new(starts_at: travel_time - 1.hour, ends_at: travel_time + 1.day, summary: "test")
        ] do
          api.stub :private_mode?, false do
            result = DeviceContent.new.call(home_assistant_api: api)

            assert_equal(result[:day_groups].count, 4)
          end
        end
      end
    end
  end

  def test_with_healthy_home_assistant
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      ha_api = new_test_api
      ha_api.stub :states_healthy?, true do
        ha_api.stub :feels_like_temperature, "72°" do
          ha_api.stub :now_playing, {} do
            ha_api.stub :top_right, [] do
              ha_api.stub :top_left, [] do
                ha_api.stub :weather_status, [] do
                  ha_api.stub :daily_events, [] do
                    result = DeviceContent.new.call(home_assistant_api: ha_api)

                    assert_equal("72°", result[:current_temperature])
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_with_private_mode
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      api = new_test_api
      api.stub :calendars_healthy?, true do
        api.stub :private_mode?, true do
          api.stub :calendar_events, [] do
            result = DeviceContent.new.call(home_assistant_api: api)

            assert result[:top_left].any? { it[:label] == "Private mode" }
          end
        end
      end
    end
  end

  def test_with_healthy_weather_api
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      api = new_test_api
      api.stub :weather_healthy?, true do
        result = DeviceContent.new.call(home_assistant_api: api)

        assert_equal 5, result[:day_groups].count
      end
    end
  end

  def test_today_not_hidden_when_periodic_events_exist
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      api = new_test_api
      events = [
        DeviceEvent.new(
          starts_at: DateTime.new(2023, 8, 27, 19, 0, 0, "-0600"),
          ends_at: DateTime.new(2023, 8, 27, 21, 0, 0, "-0600"),
          summary: "Evening event"
        )
      ]
      api.stub :calendars_healthy?, false do
        api.stub :private_mode?, false do
          api.stub :calendar_events, events do
            result = DeviceContent.new.call(home_assistant_api: api)

            assert_equal 5, result[:day_groups].count
          end
        end
      end
    end
  end

  def test_serializes_events_with_icons_and_locations
    travel_to DateTime.new(2023, 8, 27, 10, 0, 0, "-0600") do
      api = new_test_api
      events = [
        DeviceEvent.new(
          starts_at: DateTime.new(2023, 8, 27, 0, 0, 0, "-0600"),
          ends_at: DateTime.new(2023, 8, 28, 0, 0, 0, "-0600"),
          summary: "All Day",
          icon: "cake-variant",
          daily: true
        ),
        DeviceEvent.new(
          starts_at: DateTime.new(2023, 8, 27, 12, 0, 0, "-0600"),
          ends_at: DateTime.new(2023, 8, 27, 13, 0, 0, "-0600"),
          summary: "Lunch",
          icon: "alpha-j",
          location: "Room A"
        )
      ]
      api.stub :calendars_healthy?, false do
        api.stub :private_mode?, false do
          api.stub :calendar_events, events do
            result = DeviceContent.new.call(home_assistant_api: api)

            today = result[:day_groups].find { |d| d[:day_name] == "Today" }
            assert today[:daily].any? { |e| e[:summary] == "All Day" && e[:icon_class] == "cake-variant" }
            assert today[:periodic].any? { |e| e[:summary] == "Lunch" && e[:icon_text] == "J" && e[:location] == "Room A" }
          end
        end
      end
    end
  end

  def test_use_day_names_option
    travel_to DateTime.new(2023, 8, 27, 10, 0, 0, "-0600") do
      result = DeviceContent.new.call(home_assistant_api: new_test_api, use_day_names: true)

      assert_equal "Sunday", result[:day_groups][0][:day_name]
      assert_equal "Monday", result[:day_groups][1][:day_name]
    end
  end

  def test_weather_row_extracts_hourly_weather
    travel_to DateTime.new(2023, 8, 27, 7, 0, 0, "-0600") do
      api = new_test_api
      weather_events = [
        DeviceEvent.new(id: "_ha_weather_hour_1", starts_at: DateTime.new(2023, 8, 27, 8, 0, 0, "-0600"), ends_at: DateTime.new(2023, 8, 27, 8, 0, 0, "-0600"), summary: "65°", icon: "weather-sunny", timezone: "America/Chicago"),
        DeviceEvent.new(id: "_ha_weather_hour_2", starts_at: DateTime.new(2023, 8, 27, 12, 0, 0, "-0600"), ends_at: DateTime.new(2023, 8, 27, 12, 0, 0, "-0600"), summary: "72°", icon: "weather-sunny", timezone: "America/Chicago"),
        DeviceEvent.new(id: "_ha_weather_hour_3", starts_at: DateTime.new(2023, 8, 27, 16, 0, 0, "-0600"), ends_at: DateTime.new(2023, 8, 27, 16, 0, 0, "-0600"), summary: "74°", icon: "weather-sunny", timezone: "America/Chicago"),
        DeviceEvent.new(id: "_ha_weather_hour_4", starts_at: DateTime.new(2023, 8, 27, 20, 0, 0, "-0600"), ends_at: DateTime.new(2023, 8, 27, 20, 0, 0, "-0600"), summary: "60°", icon: "weather-night", timezone: "America/Chicago")
      ]
      api.stub :calendars_healthy?, false do
        api.stub :private_mode?, false do
          api.stub :calendar_events, weather_events do
            result = DeviceContent.new.call(home_assistant_api: api, weather_row: true)

            today = result[:day_groups].find { |d| d[:day_name] == "Today" }
            assert_equal 3, today[:weather_row].length
            assert today[:weather_row].any? { |w| w[:summary] == "65°" }
            assert today[:weather_row].any? { |w| w[:summary] == "72°" }
            assert today[:weather_row].any? { |w| w[:summary] == "74°" }
            assert today[:periodic].none? { |e| e[:summary] == "65°" }
          end
        end
      end
    end
  end

  def test_include_daily_weather_false_skips_daily_weather
    travel_to DateTime.new(2023, 8, 27, 10, 0, 0, "-0600") do
      api = new_test_api
      api.stub :weather_healthy?, true do
        result = DeviceContent.new.call(home_assistant_api: api, include_daily_weather: false)

        assert_equal 5, result[:day_groups].count
      end
    end
  end

  def test_start_time_only_flag
    travel_to DateTime.new(2023, 8, 27, 10, 0, 0, "-0600") do
      result = DeviceContent.new.call(home_assistant_api: new_test_api, start_time_only: true)

      assert result[:start_time_only]
    end
  end
end

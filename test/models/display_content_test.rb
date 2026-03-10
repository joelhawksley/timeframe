# frozen_string_literal: true

require "test_helper"

class DisplayContenttTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def setup
    # Clear API caches to prevent test order pollution
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_api")
    Rails.cache.delete(DEPLOY_TIME.to_s + "weather_kit_api")
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_weather_api")
  end

  def test_no_data
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      result = DisplayContent.new.call

      assert_nil(result[:current_temperature])
      assert_equal(result[:day_groups].count, 5)
    end
  end

  def test_hide_events_after_cutoff
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      result = DisplayContent.new.call

      assert_equal(result[:day_groups].count, 4)
    end
  end

  def test_hide_events_after_cutoff_if_periodic_extends_to_tomorrow
    travel_time = DateTime.new(2023, 8, 27, 20, 15, 0, "-0600")
    travel_to travel_time do
      api = HomeAssistantCalendarApi.new
      api.stub :healthy?, true do
        api.stub :data, [
          CalendarEvent.new(starts_at: travel_time - 1.hour, ends_at: travel_time + 1.day, summary: "test")
        ] do
          result = DisplayContent.new.call(home_assistant_calendar_api: api)

          assert_equal(result[:day_groups].count, 4)
        end
      end
    end
  end

  def test_with_healthy_home_assistant
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      ha_api = HomeAssistantApi.new
      ha_api.stub :healthy?, true do
        ha_api.stub :feels_like_temperature, "72°" do
          ha_api.stub :now_playing, {} do
            ha_api.stub :top_right, [] do
              ha_api.stub :top_left, [] do
                ha_api.stub :weather_status, [] do
                  ha_api.stub :daily_events, [] do
                    result = DisplayContent.new.call(home_assistant_api: ha_api)

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

  def test_with_healthy_weather_kit
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      wk_api = WeatherKitApi.new
      wk_api.stub :healthy?, true do
        wk_api.stub :daily_calendar_events, [] do
          wk_api.stub :hourly_calendar_events, [] do
            wk_api.stub :precip_calendar_events, [] do
              wk_api.stub :wind_calendar_events, [] do
                wk_api.stub :weather_alert_calendar_events, [] do
                  wk_api.stub :data, {forecastNextHour: {summary: [{condition: "rain"}], minutes: [{precipitationIntensity: 0.5}]}} do
                    result = DisplayContent.new.call(weather_kit_api: wk_api)

                    assert_equal("weather-rainy", result[:minutely_weather_minutes_icon])
                    assert_equal([{precipitationIntensity: 0.5}], result[:minutely_weather_minutes])
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_with_healthy_weather_kit_snow_condition
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      wk_api = WeatherKitApi.new
      wk_api.stub :healthy?, true do
        wk_api.stub :daily_calendar_events, [] do
          wk_api.stub :hourly_calendar_events, [] do
            wk_api.stub :precip_calendar_events, [] do
              wk_api.stub :wind_calendar_events, [] do
                wk_api.stub :weather_alert_calendar_events, [] do
                  wk_api.stub :data, {forecastNextHour: {summary: [{condition: "snow"}], minutes: []}} do
                    result = DisplayContent.new.call(weather_kit_api: wk_api)

                    assert_equal("snowflake", result[:minutely_weather_minutes_icon])
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_with_healthy_weather_kit_clear_condition
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      wk_api = WeatherKitApi.new
      wk_api.stub :healthy?, true do
        wk_api.stub :daily_calendar_events, [] do
          wk_api.stub :hourly_calendar_events, [] do
            wk_api.stub :precip_calendar_events, [] do
              wk_api.stub :wind_calendar_events, [] do
                wk_api.stub :weather_alert_calendar_events, [] do
                  wk_api.stub :data, {forecastNextHour: {summary: [{condition: "clear"}]}} do
                    result = DisplayContent.new.call(weather_kit_api: wk_api)

                    assert_nil result[:minutely_weather_minutes_icon]
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_with_healthy_weather_kit_nil_summary
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      wk_api = WeatherKitApi.new
      wk_api.stub :healthy?, true do
        wk_api.stub :daily_calendar_events, [] do
          wk_api.stub :hourly_calendar_events, [] do
            wk_api.stub :precip_calendar_events, [] do
              wk_api.stub :wind_calendar_events, [] do
                wk_api.stub :weather_alert_calendar_events, [] do
                  wk_api.stub :data, {} do
                    result = DisplayContent.new.call(weather_kit_api: wk_api)

                    # When no forecastNextHour data, condition is nil which != "clear"
                    assert_equal "weather-rainy", result[:minutely_weather_minutes_icon]
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
      cal_api = HomeAssistantCalendarApi.new
      cal_api.stub :healthy?, true do
        cal_api.stub :private_mode?, true do
          cal_api.stub :data, [] do
            result = DisplayContent.new.call(home_assistant_calendar_api: cal_api)

            assert result[:top_left].any? { it[:label] == "Private mode" }
          end
        end
      end
    end
  end

  def test_with_healthy_weather_api
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      weather_api = HomeAssistantWeatherApi.new
      weather_api.stub :healthy?, true do
        result = DisplayContent.new.call(home_assistant_weather_api: weather_api)

        assert_equal 5, result[:day_groups].count
      end
    end
  end

  def test_today_not_hidden_when_periodic_events_exist
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      cal_api = HomeAssistantCalendarApi.new
      events = [
        CalendarEvent.new(
          starts_at: DateTime.new(2023, 8, 27, 19, 0, 0, "-0600"),
          ends_at: DateTime.new(2023, 8, 27, 21, 0, 0, "-0600"),
          summary: "Evening event"
        )
      ]
      cal_api.stub :healthy?, false do
        cal_api.stub :private_mode?, false do
          cal_api.stub :data, events do
            result = DisplayContent.new.call(home_assistant_calendar_api: cal_api)

            assert_equal 5, result[:day_groups].count
          end
        end
      end
    end
  end

  def test_unhealthy_weather_kit_shows_alert
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      wk_api = WeatherKitApi.new
      wk_api.stub :healthy?, false do
        result = DisplayContent.new.call(weather_kit_api: wk_api)

        assert result[:top_left].any? { it[:label] == "Apple Weather" }
      end
    end
  end
end

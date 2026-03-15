# frozen_string_literal: true

require "test_helper"

class DisplayContenttTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def setup
    # Clear API caches to prevent test order pollution
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_api")
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
      api = HomeAssistantApi.new
      api.stub :calendars_healthy?, false do
        api.stub :calendar_events, [
          CalendarEvent.new(starts_at: travel_time - 1.hour, ends_at: travel_time + 1.day, summary: "test")
        ] do
          api.stub :private_mode?, false do
            result = DisplayContent.new.call(home_assistant_api: api)

            assert_equal(result[:day_groups].count, 4)
          end
        end
      end
    end
  end

  def test_with_healthy_home_assistant
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      ha_api = HomeAssistantApi.new
      ha_api.stub :states_healthy?, true do
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

  def test_with_private_mode
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      api = HomeAssistantApi.new
      api.stub :calendars_healthy?, true do
        api.stub :private_mode?, true do
          api.stub :calendar_events, [] do
            result = DisplayContent.new.call(home_assistant_api: api)

            assert result[:top_left].any? { it[:label] == "Private mode" }
          end
        end
      end
    end
  end

  def test_with_healthy_weather_api
    travel_to DateTime.new(2023, 8, 27, 18, 15, 0, "-0600") do
      api = HomeAssistantApi.new
      api.stub :weather_healthy?, true do
        result = DisplayContent.new.call(home_assistant_api: api)

        assert_equal 5, result[:day_groups].count
      end
    end
  end

  def test_today_not_hidden_when_periodic_events_exist
    travel_to DateTime.new(2023, 8, 27, 20, 15, 0, "-0600") do
      api = HomeAssistantApi.new
      events = [
        CalendarEvent.new(
          starts_at: DateTime.new(2023, 8, 27, 19, 0, 0, "-0600"),
          ends_at: DateTime.new(2023, 8, 27, 21, 0, 0, "-0600"),
          summary: "Evening event"
        )
      ]
      api.stub :calendars_healthy?, false do
        api.stub :private_mode?, false do
          api.stub :calendar_events, events do
            result = DisplayContent.new.call(home_assistant_api: api)

            assert_equal 5, result[:day_groups].count
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class HomeAssistantApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_garage_door_open_no_data
    HomeAssistantApi.stub :data, [] do
      refute(HomeAssistantApi.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_closed
    HomeAssistantApi.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "closed"}
      ]
    ) do
      refute(HomeAssistantApi.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open
    HomeAssistantApi.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "open"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "closed"}
      ]
    ) do
      assert(HomeAssistantApi.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open_2
    HomeAssistantApi.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "open"}
      ]
    ) do
      assert(HomeAssistantApi.garage_door_open?)
    end
  end

  def test_package_present_no_data
    HomeAssistantApi.stub :data, [] do
      refute(HomeAssistantApi.garage_door_open?)
    end
  end

  def test_package_present_with_state_off
    HomeAssistantApi.stub :data, [{"entity_id" => Timeframe::Application.config.local["home_assistant_package_box_entity_id"], "state" => "off"}] do
      refute(HomeAssistantApi.package_present?)
    end
  end

  def test_package_present_with_state_on
    HomeAssistantApi.stub :data, [{"entity_id" => Timeframe::Application.config.local["home_assistant_package_box_entity_id"], "state" => "on"}] do
      assert(HomeAssistantApi.package_present?)
    end
  end

  def test_hot_water_low
    HomeAssistantApi.stub :data, [{"entity_id" => Timeframe::Application.config.local["home_assistant_available_hot_water_entity_id"], "state" => "8"}] do
      refute(HomeAssistantApi.hot_water_heater_healthy?)
    end
  end

  def test_feels_like_temperature_no_data
    assert_nil(HomeAssistantApi.feels_like_temperature)
  end

  def test_feels_like_temperature
    HomeAssistantApi.stub :data, [{"entity_id" => "sensor.weather_station_feels_like", "state" => "49.712"}] do
      assert_equal(HomeAssistantApi.feels_like_temperature, 49)
    end
  end

  def test_fetch
    VCR.use_cassette(:home_assistant_states) do
      HomeAssistantApi.fetch

      assert(HomeAssistantApi.data.length > 20)
    end
  end

  def test_health_no_fetched_at
    HomeAssistantApi.stub :last_fetched_at, nil do
      assert(!HomeAssistantApi.healthy?)
    end
  end

  def test_health_current_fetched_at
    HomeAssistantApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(HomeAssistantApi.healthy?)
      end
    end
  end

  def test_health_stale_fetched_at
    HomeAssistantApi.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(HomeAssistantApi.healthy?)
      end
    end
  end

  def test_dryer_needs_attention_no_data
    assert_nil(HomeAssistantApi.dryer_needs_attention?)
  end

  def test_dryer_needs_attention
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_dryer_door_entity_id"],
        "state" => "off",
        "last_changed" => "2024-04-20T13:14:09.114746+00:00"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_dryer_state_entity_id"],
        "state" => "Off",
        "last_changed" => "2024-04-20T14:08:54.382832+00:00"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert(HomeAssistantApi.dryer_needs_attention?)
    end
  end

  def test_washer_needs_attention_no_data
    assert_nil(HomeAssistantApi.washer_needs_attention?)
  end

  def test_washer_needs_attention
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_washer_state_entity_id"],
        "state" => "Off",
        "last_changed" => "2024-04-20T14:26:45.640590+00:00"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_washer_door_entity_id"],
        "state" => "off",
        "last_changed" => "2024-04-20T13:15:17.285120+00:00"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert(HomeAssistantApi.washer_needs_attention?)
    end
  end

  def test_car_needs_plugged_in
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_west_charger_entity_id"],
        "state" => "not_connected"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_rav4_entity_id"],
        "state" => "garage"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert(HomeAssistantApi.car_needs_plugged_in?)
    end
  end

  def test_open_doors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["exterior_door_sensors"][0],
        "state" => "on"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert_equal(HomeAssistantApi.open_doors, ["Alley"])
    end
  end

  def test_unlocked_doors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["exterior_door_locks"][0],
        "state" => "unlocked"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert_equal(HomeAssistantApi.unlocked_doors, ["Patio"])
    end
  end

  def test_unavailable_door_sensors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["exterior_door_locks"][0],
        "state" => "unavailable"
      }
    ]

    HomeAssistantApi.stub :data, data do
      assert_equal(HomeAssistantApi.unavailable_door_sensors, ["Patio door lock"])
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class HomeAssistantApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_garage_door_open_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      refute(api.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_closed
    api = HomeAssistantApi.new
    api.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_2_entity_id"], "state" => "closed"}
      ]
    ) do
      refute(api.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open
    api = HomeAssistantApi.new
    api.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_entity_id"], "state" => "open"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_2_entity_id"], "state" => "closed"}
      ]
    ) do
      assert(api.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open_2
    api = HomeAssistantApi.new
    api.stub(
      :data,
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant"]["garage_door_2_entity_id"], "state" => "open"}
      ]
    ) do
      assert(api.garage_door_open?)
    end
  end

  def test_package_present_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      refute(api.garage_door_open?)
    end
  end

  def test_package_present_with_state_off
    api = HomeAssistantApi.new
    api.stub :data, [{"entity_id" => Timeframe::Application.config.local["home_assistant"]["package_box_entity_id"], "state" => "off"}] do
      refute(api.package_present?)
    end
  end

  def test_package_present_with_state_on
    api = HomeAssistantApi.new
    api.stub :data, [{"entity_id" => Timeframe::Application.config.local["home_assistant"]["package_box_entity_id"], "state" => "on"}] do
      assert(api.package_present?)
    end
  end

  def test_feels_like_temperature_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      assert_nil(api.feels_like_temperature)
    end
  end

  def test_feels_like_temperature
    api = HomeAssistantApi.new
    api.stub :data, [{"entity_id" => "sensor.weather_station_feels_like", "state" => "49.712"}] do
      assert_equal(api.feels_like_temperature, 49)
    end
  end

  def test_fetch
    VCR.use_cassette(:home_assistant_states) do
      api = HomeAssistantApi.new
      api.fetch

      assert(api.data.length > 1)
    end
  end

  def test_health_no_fetched_at
    api = HomeAssistantApi.new
    api.stub :last_fetched_at, nil do
      assert(!api.healthy?)
    end
  end

  def test_health_current_fetched_at
    api = HomeAssistantApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(api.healthy?)
      end
    end
  end

  def test_health_stale_fetched_at
    api = HomeAssistantApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(api.healthy?)
      end
    end
  end

  def test_dryer_needs_attention_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      assert_nil(api.dryer_needs_attention?)
    end
  end

  def test_dryer_needs_attention
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["dryer_door_entity_id"],
        "state" => "off",
        "last_changed" => "2024-04-20T13:14:09.114746+00:00"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["dryer_state_entity_id"],
        "state" => "Off",
        "last_changed" => "2024-04-20T14:08:54.382832+00:00"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert(api.dryer_needs_attention?)
    end
  end

  def test_washer_needs_attention_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      assert_nil(api.washer_needs_attention?)
    end
  end

  def test_washer_needs_attention
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["washer_state_entity_id"],
        "state" => "Off",
        "last_changed" => "2024-04-20T14:26:45.640590+00:00"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["washer_door_entity_id"],
        "state" => "off",
        "last_changed" => "2024-04-20T13:15:17.285120+00:00"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert(api.washer_needs_attention?)
    end
  end

  def test_car_needs_plugged_in
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["west_charger_entity_id"],
        "state" => "not_connected"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["rav4_entity_id"],
        "state" => "garage"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert(api.car_needs_plugged_in?)
    end
  end

  def test_open_doors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["exterior_door_sensors"][0],
        "state" => "on"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.open_doors, ["Alley"])
    end
  end

  def test_unlocked_doors_ignores_open_doors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["exterior_door_sensors"][2],
        "state" => "on"
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["exterior_door_locks"][0],
        "state" => "unlocked"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.unlocked_doors, [])
    end
  end

  def test_unlocked_doors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["exterior_door_locks"][0],
        "state" => "unlocked"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.unlocked_doors, ["Patio"])
    end
  end

  def test_unavailable_door_sensors
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["exterior_door_locks"][0],
        "state" => "unavailable"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.unavailable_door_sensors, ["Patio door lock"])
    end
  end

  def test_low_batteries
    data = [
      {
        "entity_id" => "sensor.laundry_room_washer_leak_sensor_battery",
        "state" => "100",
        "attributes" => { "device_class" => "battery" }
      },
      {
        "entity_id" => "sensor.laundry_room_sink_leak_sensor_battery",
        "state" => "5",
        "attributes" => { "device_class" => "battery" }
      },
      {
        "entity_id" => "sensor.unknown_leak_sensor_battery",
        "state" => "unknown",
        "attributes" => { "device_class" => "battery" }
      },
      {
        "entity_id" => "sensor.unknown_leak_sensor_battery",
        "state" => "unavailable",
        "attributes" => { "device_class" => "battery" }
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.low_batteries, ["Laundry room sink leak sensor"])
    end
  end

  def test_active_video_call
    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["audio_input_in_use"],
        "state" => "on"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert(api.active_video_call?)
    end

    api = HomeAssistantApi.new
    api.stub :data, {} do
      refute(api.active_video_call?)
    end
  end

  def test_roborock_errors
    api = HomeAssistantApi.new
    api.stub :data, {} do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["roborock_dock_error"],
        "state" => "ok"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["roborock_dock_error"],
        "state" => "water_empty"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Water empty"])
    end

    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["roborock_vacuum_error"],
        "state" => "none"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant"]["roborock_vacuum_error"],
        "state" => "bumper_stuck"
      }
    ]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Bumper stuck"])
    end
  end
end

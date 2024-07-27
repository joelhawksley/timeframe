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
    config = {
      "home_assistant" => {
        "garage_door_entity_id" => "garage_door",
        "garage_door_2_entity_id" => "garage_door_2"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub(
      :data,
      [
        {entity_id: "garage_door", state: "closed"},
        {entity_id: "garage_door_2", state: "closed"}
      ]
    ) do
      refute(api.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open
    config = {
      "home_assistant" => {
        "garage_door_entity_id" => "garage_door",
        "garage_door_2_entity_id" => "garage_door_2"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub(
      :data,
      [
        {entity_id: "garage_door", state: "open"},
        {entity_id: "garage_door_2", state: "closed"}
      ]
    ) do
      assert(api.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open_2
    config = {
      "home_assistant" => {
        "garage_door_entity_id" => "garage_door",
        "garage_door_2_entity_id" => "garage_door_2"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub(
      :data,
      [
        {entity_id: "garage_door", state: "closed"},
        {entity_id: "garage_door_2", state: "open"}
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
    config = {
      "home_assistant" => {
        "package_box_entity_id" => "package_box"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub :data, [{entity_id: "package_box", state: "off"}] do
      refute(api.package_present?)
    end
  end

  def test_package_present_with_state_on
    config = {
      "home_assistant" => {
        "package_box_entity_id" => "package_box"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub :data, [{entity_id: "package_box", state: "on"}] do
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
    config = {
      "home_assistant" => {
        "weather_feels_like_entity_id" => "feels_like"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub :data, [{entity_id: "feels_like", state: "49.712"}] do
      assert_equal("49°", api.feels_like_temperature)
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
    config = {
      "home_assistant" => {
        "dryer_door_entity_id" => "dryer_door",
        "dryer_state_entity_id" => "dryer_state"
      }
    }

    data = [
      {
        entity_id: "dryer_door",
        state: "off",
        last_changed: "2024-04-20T13:14:09.114746+00:00"
      },
      {
        entity_id: "dryer_state",
        state: "Off",
        last_changed: "2024-04-20T14:08:54.382832+00:00"
      }
    ]

    api = HomeAssistantApi.new(config)
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
    config = {
      "home_assistant" => {
        "washer_door_entity_id" => "washer_door",
        "washer_state_entity_id" => "washer_state"
      }
    }

    data = [
      {
        entity_id: "washer_state",
        state: "Off",
        last_changed: "2024-04-20T14:26:45.640590+00:00"
      },
      {
        entity_id: "washer_door",
        state: "off",
        last_changed: "2024-04-20T13:15:17.285120+00:00"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.washer_needs_attention?)
    end
  end

  def test_car_needs_plugged_in
    config = {
      "home_assistant" => {
        "west_charger_entity_id" => "west_charger",
        "rav4_entity_id" => "rav4"
      }
    }

    data = [
      {
        entity_id: "west_charger",
        state: "not_connected"
      },
      {
        entity_id: "rav4",
        state: "garage"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.car_needs_plugged_in?)
    end
  end

  def test_open_doors
    config = {
      "home_assistant" => {
        "exterior_door_sensors" => [
          "alley_door_sensor"
        ]
      }
    }

    data = [
      {
        entity_id: "alley_door_sensor",
        state: "on"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.open_doors, ["Alley"])
    end
  end

  def test_unlocked_doors_ignores_open_doors
    config = {
      "home_assistant" => {
        "exterior_door_sensors" => [
          "alley_door_sensor"
        ],
        "exterior_door_locks" => [
          "alley_door_lock"
        ]
      }
    }

    data = [
      {
        entity_id: "alley_door_sensor",
        state: "on"
      },
      {
        entity_id: "alley_door_lock",
        state: "off"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.unlocked_doors, [])
    end
  end

  def test_unlocked_doors
    config = {
      "home_assistant" => {
        "exterior_door_sensors" => [],
        "exterior_door_locks" => [
          "patio_door_lock"
        ]
      }
    }

    data = [
      {
        entity_id: "patio_door_lock",
        state: "off"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.unlocked_doors, ["Patio"])
    end
  end

  def test_unavailable_door_sensors
    config = {
      "home_assistant" => {
        "exterior_door_sensors" => ["alley_door_sensor"]
      }
    }

    data = [
      {
        entity_id: "alley_door_sensor",
        state: "unavailable"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.unavailable_door_sensors, ["Alley door sensor"])
    end
  end

  def test_low_batteries
    data = [
      {
        entity_id: "sensor.laundry_room_washer_leak_sensor_battery",
        state: "100",
        attributes: {device_class: "battery"}
      },
      {
        entity_id: "sensor.laundry_room_sink_leak_sensor_battery",
        state: "5",
        attributes: {device_class: "battery"}
      },
      {
        entity_id: "sensor.unknown_leak_sensor_battery",
        state: "unknown",
        attributes: {device_class: "battery"}
      },
      {
        entity_id: "sensor.unknown_leak_sensor_battery",
        state: "unavailable",
        attributes: {device_class: "battery"}
      }
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.low_batteries, ["Laundry room sink leak sensor"])
    end
  end

  def test_active_video_call
    config = {
      "home_assistant" => {
        "audio_input_in_use" => "audio_input"
      }
    }

    data = [
      {
        entity_id: "audio_input",
        state: "on"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.active_video_call?)
    end

    api = HomeAssistantApi.new(config)
    api.stub :data, {} do
      refute(api.active_video_call?)
    end
  end

  def test_online
    config = {
      "home_assistant" => {
        "ping_sensor_entity_id" => "ping_sensor"
      }
    }

    data = [
      {
        entity_id: "ping_sensor",
        state: "on"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.online?)
    end

    api = HomeAssistantApi.new(config)
    api.stub :data, {} do
      refute(api.online?)
    end
  end

  def test_nas_online
    config = {
      "home_assistant" => {
        "nas_temperature_entity_id" => "nas_temperature"
      }
    }

    data = [
      {
        entity_id: "nas_temperature",
        state: "100"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.nas_online?)
    end

    data = [
      {
        entity_id: "nas_temperature",
        state: "unavailable"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      refute(api.nas_online?)
    end

    api = HomeAssistantApi.new(config)
    api.stub :data, {} do
      refute(api.nas_online?)
    end
  end

  def test_roborock_errors
    config = {
      "home_assistant" => {
        "roborock_dock_error" => "roborock_dock_error",
        "roborock_vacuum_error" => "roborock_vacuum_error",
        "roborock_status" => "roborock_status",
        "roborock_sensor_time_left" => "roborock_sensor_time_left"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub :data, {} do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        entity_id: "roborock_dock_error",
        state: "ok"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        entity_id: "roborock_dock_error",
        state: "water_empty"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Water empty"])
    end

    data = [
      {
        entity_id: "roborock_vacuum_error",
        state: "none"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, [])
    end

    data = [
      {
        entity_id: "roborock_vacuum_error",
        state: "bumper_stuck"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Bumper stuck"])
    end

    data = [
      {
        entity_id: "roborock_status",
        state: "charger_disconnected"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Return to charger"])
    end

    data = [
      {
        entity_id: "roborock_status",
        state: "idle"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Return to charger"])
    end

    data = [
      {
        entity_id: "roborock_sensor_time_left",
        state: "-17031"
      }
    ]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.roborock_errors, ["Sensor maintenance"])
    end
  end
end

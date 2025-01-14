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
        state: "home"
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

  def test_now_playing_no_data
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    api = HomeAssistantApi.new(config)
    api.stub :data, [] do
      assert_equal(api.now_playing, {})
    end
  end

  def test_now_playing_paused
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    data = [{entity_id: "media_player_entity_id", state: "paused"}]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.now_playing, {})
    end
  end

  def test_now_playing_with_media_title
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    data = [{
      entity_id: "media_player_entity_id",
      state: "playing",
      attributes: {
        media_title: "Snoozy Stardust",
        media_artist: "COSMOGLOW"
      }
    }]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.now_playing, {artist: "COSMOGLOW", track: "Snoozy Stardust"})
    end
  end

  def test_now_playing_with_cpr_news
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    data = [{
      entity_id: "media_player_entity_id",
      state: "playing",
      attributes: {
        media_title: "CPR News -- Today, Explained",
        media_artist: "CPR News -- Today, Explained"
      }
    }]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.now_playing, {artist: "CPR News", track: "Today, Explained"})
    end
  end

  def test_now_playing_with_cpr_classical
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    data = [{
      entity_id: "media_player_entity_id",
      state: "playing",
      attributes: {
        media_channel: "Colorado Public Radio Classical • Live Classical Music",
        media_title:
     "Fantasia on a Theme by Thomas Tallis by Ralph Vaughan Williams -- Vaughan Williams: Wasps Overture /"
      }
    }]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.now_playing, {artist: "Thomas Tallis", track: "Fantasia on a Theme"})
    end
  end

  def test_now_playing_with_folk_alley
    config = {
      "home_assistant" => {
        "media_player_entity_id" => "media_player_entity_id"
      }
    }

    data = [{
      entity_id: "media_player_entity_id",
      state: "playing",
      attributes: {
        media_title: "The Decemberists - The King Is Dead",
        media_channel: "Folk Alley - WKSU-HD2 • Folk Alley"
      }
    }]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert_equal(api.now_playing, {artist: "The Decemberists", track: "The King Is Dead"})
    end
  end

  def test_problems
    data = [{entity_id: "binary_sensor.timeframe0print0printer_ink_low", state: "on"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [{icon: "print", message: "Printer ink low"}])
    end
  end
end

# frozen_string_literal: true

require "test_helper"

class HomeAssistantApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_feels_like_temperature_no_data
    api = HomeAssistantApi.new
    api.stub :data, [] do
      assert_nil(api.feels_like_temperature)
    end
  end

  def test_feels_like_temperature
    api = HomeAssistantApi.new
    api.stub :data, [
      {entity_id: "sensor.timeframe_weather_feels_like_entity_id", state: "sensor.feels_like"},
      {entity_id: "sensor.feels_like", state: "49.712"}
    ] do
      assert_equal("49°", api.feels_like_temperature)
    end
  end

  def test_feels_like_temperature_falls_back_to_weather_entity
    api = HomeAssistantApi.new
    api.stub :data, [
      {entity_id: "weather.my_weather", state: "sunny", attributes: {apparent_temperature: 72.3}}
    ] do
      assert_equal("72°", api.feels_like_temperature)
    end
  end

  def test_weather_entity_id_from_timeframe_sensor
    api = HomeAssistantApi.new
    api.stub :data, [
      {entity_id: "sensor.timeframe_weather_entity_id", state: "weather.custom"},
      {entity_id: "weather.default", state: "sunny"}
    ] do
      assert_equal("weather.custom", api.weather_entity_id)
    end
  end

  def test_weather_entity_id_falls_back_to_first_weather_entity
    api = HomeAssistantApi.new
    api.stub :data, [
      {entity_id: "weather.my_weather", state: "sunny"}
    ] do
      assert_equal("weather.my_weather", api.weather_entity_id)
    end
  end

  def test_weather_entity_id_returns_nil_when_no_weather
    api = HomeAssistantApi.new
    api.stub :data, [] do
      assert_nil(api.weather_entity_id)
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

  def test_now_playing_no_data
    api = HomeAssistantApi.new({})
    api.stub :data, [] do
      assert_equal({}, api.now_playing)
    end
  end

  def test_now_playing_no_media_player_entity
    data = [
      {entity_id: "sensor.timeframe_media_player_entity_id", state: "media_player.living_room"}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({}, api.now_playing)
    end
  end

  def test_now_playing_paused
    data = [
      {entity_id: "sensor.timeframe_media_player_entity_id", state: "media_player.living_room"},
      {entity_id: "media_player.living_room", state: "paused", attributes: {media_artist: "COSMOGLOW", media_title: "Snoozy Stardust"}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({}, api.now_playing)
    end
  end

  def test_now_playing_idle
    data = [
      {entity_id: "sensor.timeframe_media_player_entity_id", state: "media_player.living_room"},
      {entity_id: "media_player.living_room", state: "idle", attributes: {media_artist: "COSMOGLOW", media_title: "Snoozy Stardust"}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({}, api.now_playing)
    end
  end

  def test_now_playing_playing
    data = [
      {entity_id: "sensor.timeframe_media_player_entity_id", state: "media_player.living_room"},
      {entity_id: "media_player.living_room", state: "playing", attributes: {media_artist: "COSMOGLOW", media_title: "Snoozy Stardust"}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({artist: "COSMOGLOW", track: "Snoozy Stardust"}, api.now_playing)
    end
  end

  def test_now_playing_artist_only
    data = [
      {entity_id: "sensor.timeframe_media_player_entity_id", state: "media_player.living_room"},
      {entity_id: "media_player.living_room", state: "playing", attributes: {media_artist: "COSMOGLOW"}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({artist: "COSMOGLOW", track: nil}, api.now_playing)
    end
  end

  def test_now_playing_falls_back_to_first_media_player
    data = [
      {entity_id: "media_player.living_room", state: "playing", attributes: {media_artist: "COSMOGLOW", media_title: "Snoozy Stardust"}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({artist: "COSMOGLOW", track: "Snoozy Stardust"}, api.now_playing)
    end
  end

  def test_top_left_csv_dedupe
    data = [{entity_id: "sensor.timeframe_top_left_front_door", state: "door-open,Front\n\n  \n      door-open,Front"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "door-open", label: "Front"}], api.top_left)
    end
  end

  def test_top_left
    data = [{entity_id: "sensor.timeframe_top_left_front_door", state: "door-open,Front"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "door-open", label: "Front"}], api.top_left)
    end
  end

  def test_top_left_with_underscore
    data = [{entity_id: "sensor.timeframe_top_left_front_door", state: "door-open,front_door_open"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "door-open", label: "Front door open"}], api.top_left)
    end
  end

  def test_top_left_capitalization
    data = [{entity_id: "sensor.timeframe_top_left_front_door", state: "crow,Great Horned"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "crow", label: "Great Horned"}], api.top_left)
    end
  end

  def test_top_left_empty
    data = [{entity_id: "sensor.timeframe_top_left_front_door", state: ""}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.top_left)
    end
  end

  def test_top_left_no_data
    api = HomeAssistantApi.new({})
    api.stub :data, [] do
      assert_equal([], api.top_left)
    end
  end

  def test_top_left_multiple_sensors
    data = [
      {entity_id: "sensor.timeframe_top_left_front_door", state: "door-open,Front"},
      {entity_id: "sensor.timeframe_top_left_patio", state: "lock-open,Patio"}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([
        {icon: "door-open", label: "Front"},
        {icon: "lock-open", label: "Patio"}
      ], api.top_left)
    end
  end

  def test_demo_mode_on
    data = [{entity_id: "input_boolean.timeframe_demo_mode", state: "on"}]

    api = HomeAssistantApi.new
    api.stub :data, data do
      assert(api.demo_mode?)
    end
  end

  def test_demo_mode_off
    data = [{entity_id: "input_boolean.timeframe_demo_mode", state: "off"}]

    api = HomeAssistantApi.new
    api.stub :data, data do
      refute(api.demo_mode?)
    end
  end

  def test_top_right_no_data
    api = HomeAssistantApi.new({})
    api.stub :data, [] do
      assert_equal([], api.top_right)
    end
  end

  def test_top_right_empty_state
    data = [{entity_id: "sensor.timeframe_top_right", state: ""}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.top_right)
    end
  end

  def test_top_right
    data = [{entity_id: "sensor.timeframe_top_right", state: "thermometer,72°"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "thermometer", label: "72°"}], api.top_right)
    end
  end

  def test_top_right_with_underscore
    data = [{entity_id: "sensor.timeframe_top_right", state: "thermometer,feels_like"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "thermometer", label: "Feels like"}], api.top_right)
    end
  end

  def test_top_right_multiple_sensors
    data = [
      {entity_id: "sensor.timeframe_top_right_temperature", state: "thermometer,72°"},
      {entity_id: "sensor.timeframe_top_right_humidity", state: "water-percent,45%"}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([
        {icon: "thermometer", label: "72°"},
        {icon: "water-percent", label: "45%"}
      ], api.top_right)
    end
  end

  def test_weather_status_no_data
    api = HomeAssistantApi.new({})
    api.stub :data, [] do
      assert_equal([], api.weather_status)
    end
  end

  def test_weather_status_empty_state
    data = [{entity_id: "sensor.timeframe_weather_status_aqi", state: ""}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.weather_status)
    end
  end

  def test_weather_status
    data = [{entity_id: "sensor.timeframe_weather_status_aqi", state: "air-filter,AQI 42"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "air-filter", label: "AQI 42"}], api.weather_status)
    end
  end

  def test_weather_status_with_rotation
    data = [{entity_id: "sensor.timeframe_weather_status_wind", state: "arrow-up,15,225"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "arrow-up", label: "15", rotation: 225}], api.weather_status)
    end
  end

  def test_weather_status_multiple_sensors
    data = [
      {entity_id: "sensor.timeframe_weather_status_aqi", state: "air-filter,AQI 42"},
      {entity_id: "sensor.timeframe_weather_status_uv", state: "white-balance-sunny,UV 6"}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([
        {icon: "air-filter", label: "AQI 42"},
        {icon: "white-balance-sunny", label: "UV 6"}
      ], api.weather_status)
    end
  end

  def test_daily_events_no_data
    api = HomeAssistantApi.new({})
    api.stub :data, [] do
      assert_equal([], api.daily_events)
    end
  end

  def test_daily_events_empty_state
    data = [{entity_id: "sensor.timeframe_daily_event_test", state: ""}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.daily_events)
    end
  end

  def test_daily_events
    data = [{entity_id: "sensor.timeframe_daily_event_trash", state: "trash-can,Trash day"}]

    api = HomeAssistantApi.new({})
    travel_to DateTime.new(2023, 8, 27, 12, 0, 0, "-0600") do
      api.stub :data, data do
        events = api.daily_events
        assert_equal(1, events.length)
        assert_equal("trash-can", events.first.icon)
        assert_equal("Trash day", events.first.summary)
        assert(events.first.daily?)
      end
    end
  end

  def test_daily_events_with_underscore
    data = [{entity_id: "sensor.timeframe_daily_event_recycle", state: "recycle,recycling_day"}]

    api = HomeAssistantApi.new({})
    travel_to DateTime.new(2023, 8, 27, 12, 0, 0, "-0600") do
      api.stub :data, data do
        events = api.daily_events
        assert_equal(1, events.length)
        assert_equal("Recycling day", events.first.summary)
      end
    end
  end

  def test_daily_events_multiple_sensors
    data = [
      {entity_id: "sensor.timeframe_daily_event_trash", state: "trash-can,Trash day"},
      {entity_id: "sensor.timeframe_daily_event_recycle", state: "recycle,Recycling"}
    ]

    api = HomeAssistantApi.new({})
    travel_to DateTime.new(2023, 8, 27, 12, 0, 0, "-0600") do
      api.stub :data, data do
        events = api.daily_events
        assert_equal(2, events.length)
        assert_equal("trash-can", events[0].icon)
        assert_equal("Trash day", events[0].summary)
        assert_equal("recycle", events[1].icon)
        assert_equal("Recycling", events[1].summary)
      end
    end
  end

  def test_daily_events_invalid_format
    data = [{entity_id: "sensor.timeframe_daily_event_test", state: "just-an-icon"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.daily_events)
    end
  end

  def test_top_right_short_parts
    data = [{entity_id: "sensor.timeframe_top_right_x", state: "onlyicon"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.top_right)
    end
  end

  def test_top_left_short_parts
    data = [{entity_id: "sensor.timeframe_top_left_x", state: "onlyicon"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.top_left)
    end
  end

  def test_weather_status_short_parts
    data = [{entity_id: "sensor.timeframe_weather_status_x", state: "onlyicon"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([], api.weather_status)
    end
  end

  def test_weather_status_without_rotation
    data = [{entity_id: "sensor.timeframe_weather_status_aqi", state: "air-filter,AQI 42"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      result = api.weather_status
      assert_equal 1, result.length
      refute result.first.key?(:rotation)
    end
  end

  def test_now_playing_no_artist_or_track
    data = [
      {entity_id: "media_player.living_room", state: "playing", attributes: {}}
    ]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal({}, api.now_playing)
    end
  end

  def test_feels_like_override_entity_missing
    api = HomeAssistantApi.new
    api.stub :data, [
      {entity_id: "sensor.timeframe_weather_feels_like_entity_id", state: "sensor.nonexistent"}
    ] do
      assert_nil(api.feels_like_temperature)
    end
  end

  def test_weather_status_with_underscore_label
    data = [{entity_id: "sensor.timeframe_weather_status_aqi", state: "air-filter,air_quality"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal([{icon: "air-filter", label: "Air quality"}], api.weather_status)
    end
  end

  def test_demo_mode_no_entity
    api = HomeAssistantApi.new
    api.stub :data, [] do
      refute(api.demo_mode?)
    end
  end
end

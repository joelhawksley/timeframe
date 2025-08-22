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

  def test_problems_csv
    data = [{entity_id: "sensor.timeframe_front_door", state: "door-open,Front"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [{icon: "door-open", message: "Front"}])
    end
  end

  def test_problems_csv_underscore
    data = [{entity_id: "sensor.timeframe_front_door", state: "door-open,front_door_open"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [{icon: "door-open", message: "Front door open"}])
    end
  end

  def test_problems_csv_capitalization
    data = [{entity_id: "sensor.timeframe_front_door", state: "crow,Great Horned"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [{icon: "crow", message: "Great Horned"}])
    end
  end

  def test_problems_csv_newlines
    data = [{entity_id: "sensor.timeframe_states", state: "door-open,Front\n\n  \n      lock-open,Patio"}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [{icon: "door-open", message: "Front"}, {icon: "lock-open", message: "Patio"}])
    end
  end

  def test_problems_csv_empty
    data = [{entity_id: "sensor.timeframe_front_door", state: ""}]

    api = HomeAssistantApi.new({})
    api.stub :data, data do
      assert_equal(api.problems, [])
    end
  end

  def test_demo_mode_on
    config = {
      "home_assistant" => {
        "demo_mode_entity_id" => "input_boolean.timeframe_demo_mode"
      }
    }

    data = [{entity_id: "input_boolean.timeframe_demo_mode", state: "on"}]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      assert(api.demo_mode?)
    end
  end

  def test_demo_mode_off
    config = {
      "home_assistant" => {
        "demo_mode_entity_id" => "input_boolean.timeframe_demo_mode"
      }
    }

    data = [{entity_id: "input_boolean.timeframe_demo_mode", state: "off"}]

    api = HomeAssistantApi.new(config)
    api.stub :data, data do
      refute(api.demo_mode?)
    end
  end
end

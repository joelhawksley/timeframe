# frozen_string_literal: true

require "test_helper"

class HomeAssistantHomeTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_garage_door_open_no_states
    HomeAssistantHome.stub :states, [] do
      refute(HomeAssistantHome.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_closed
    HomeAssistantHome.stub(
      :states, 
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "closed"},
      ]
    ) do
      refute(HomeAssistantHome.garage_door_open?)
    end
  end


  def test_garage_door_open_with_state_open
    HomeAssistantHome.stub(
      :states, 
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "open"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "closed"},
      ]
    ) do
      assert(HomeAssistantHome.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open_2
    HomeAssistantHome.stub(
      :states, 
      [
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "closed"},
        {"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_2_entity_id"], "state" => "open"},
      ]
    ) do
      assert(HomeAssistantHome.garage_door_open?)
    end
  end

  def test_package_present_no_states
    HomeAssistantHome.stub :states, [] do
      refute(HomeAssistantHome.garage_door_open?)
    end
  end

  def test_package_present_with_state_off
    HomeAssistantHome.stub :states, [{"entity_id" => Timeframe::Application.config.local["home_assistant_package_box_entity_id"], "state" => "off"}] do
      refute(HomeAssistantHome.package_present?)
    end
  end

  def test_package_present_with_state_on
    HomeAssistantHome.stub :states, [{"entity_id" => Timeframe::Application.config.local["home_assistant_package_box_entity_id"], "state" => "on"}] do
      assert(HomeAssistantHome.package_present?)
    end
  end

  def test_hot_water_low
    HomeAssistantHome.stub :states, [{"entity_id" => Timeframe::Application.config.local["home_assistant_available_hot_water_entity_id"], "state" => "8"}] do
      refute(HomeAssistantHome.hot_water_heater_healthy?)
    end
  end

  def test_feels_like_temperature_no_data
    assert_nil(HomeAssistantHome.feels_like_temperature)
  end

  def test_feels_like_temperature
    HomeAssistantHome.stub :states, [{"entity_id"=>"sensor.weather_station_feels_like", "state"=>"49.712"}] do
      assert_equal(HomeAssistantHome.feels_like_temperature, 49)
    end
  end

  def test_fetch
    VCR.use_cassette(:home_assistant_states) do
      HomeAssistantHome.fetch

      assert(HomeAssistantHome.states.length > 20)
    end
  end

  def test_health_no_fetched_at
    HomeAssistantHome.stub :last_fetched_at, nil do
      assert(!HomeAssistantHome.healthy?)
    end
  end

  def test_health_current_fetched_at
    HomeAssistantHome.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(HomeAssistantHome.healthy?)
      end
    end
  end

  def test_health_stale_fetched_at
    HomeAssistantHome.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(HomeAssistantHome.healthy?)
      end
    end
  end

  def test_dryer_needs_attention_no_data
    assert_nil(HomeAssistantHome.dryer_needs_attention?)
  end

  def test_dryer_needs_attention
    states = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_dryer_door_entity_id"],
        "state" => "off",
        "last_changed"=>"2024-04-20T13:14:09.114746+00:00",
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_dryer_state_entity_id"],
        "state" => "Off",
        "last_changed"=>"2024-04-20T14:08:54.382832+00:00",
      }
    ]

    HomeAssistantHome.stub :states, states do
      assert(HomeAssistantHome.dryer_needs_attention?)
    end
  end

  def test_washer_needs_attention_no_data
    assert_nil(HomeAssistantHome.washer_needs_attention?)
  end

  def test_washer_needs_attention
    states = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_washer_state_entity_id"],
        "state" => "Off",
        "last_changed" => "2024-04-20T14:26:45.640590+00:00",
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_washer_door_entity_id"],
        "state" => "off",
        "last_changed" => "2024-04-20T13:15:17.285120+00:00",
      }
    ]

    HomeAssistantHome.stub :states, states do
      assert(HomeAssistantHome.washer_needs_attention?)
    end
  end

  def test_car_needs_plugged_in
    states = [
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_west_charger_entity_id"],
        "state" => "not_connected",
      },
      {
        "entity_id" => Timeframe::Application.config.local["home_assistant_rav4_entity_id"],
        "state" => "garage",
      }
    ]

    HomeAssistantHome.stub :states, states do
      assert(HomeAssistantHome.car_needs_plugged_in?)
    end
  end

  def test_open_doors
    states = [
      {
        "entity_id" => Timeframe::Application.config.local["exterior_door_sensors"][0],
        "state" => "on",
      }
    ]

    HomeAssistantHome.stub :states, states do
      assert_equal(HomeAssistantHome.open_doors, ["Alley"])
    end
  end

  def test_unlocked_doors
    states = [
      {
        "entity_id" => Timeframe::Application.config.local["exterior_door_locks"][0],
        "state" => "unlocked",
      }
    ]

    HomeAssistantHome.stub :states, states do
      assert_equal(HomeAssistantHome.unlocked_doors, ["Patio"])
    end
  end
end

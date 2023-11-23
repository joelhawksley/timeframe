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
    HomeAssistantHome.stub :states, [{"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "closed"}] do
      refute(HomeAssistantHome.garage_door_open?)
    end
  end

  def test_garage_door_open_with_state_open
    HomeAssistantHome.stub :states, [{"entity_id" => Timeframe::Application.config.local["home_assistant_garage_door_entity_id"], "state" => "open"}] do
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
end

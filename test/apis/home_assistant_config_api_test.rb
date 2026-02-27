# frozen_string_literal: true

require "test_helper"

class HomeAssistantConfigApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_latitude
    api = HomeAssistantConfigApi.new
    api.stub :data, {latitude: 38.4937, longitude: -98.7675} do
      assert_equal("38.4937", api.latitude)
    end
  end

  def test_longitude
    api = HomeAssistantConfigApi.new
    api.stub :data, {latitude: 38.4937, longitude: -98.7675} do
      assert_equal("-98.7675", api.longitude)
    end
  end

  def test_latitude_no_data
    api = HomeAssistantConfigApi.new
    api.stub :data, {} do
      assert_nil(api.latitude)
    end
  end

  def test_longitude_no_data
    api = HomeAssistantConfigApi.new
    api.stub :data, {} do
      assert_nil(api.longitude)
    end
  end

  def test_fetch
    VCR.use_cassette(:home_assistant_config) do
      api = HomeAssistantConfigApi.new
      api.fetch

      assert_equal("38.4937", api.latitude)
      assert_equal("-98.7675", api.longitude)
      assert_equal("America/Chicago", api.time_zone)
    end
  end

  def test_time_zone
    api = HomeAssistantConfigApi.new
    api.stub :data, {time_zone: "America/Denver"} do
      assert_equal("America/Denver", api.time_zone)
    end
  end

  def test_time_zone_no_data
    api = HomeAssistantConfigApi.new
    api.stub :data, {} do
      assert_nil(api.time_zone)
    end
  end

  def test_health_no_fetched_at
    api = HomeAssistantConfigApi.new
    api.stub :last_fetched_at, nil do
      refute(api.healthy?)
    end
  end

  def test_health_current_fetched_at
    api = HomeAssistantConfigApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 15, 15, 0, "-0600") do
        assert(api.healthy?)
      end
    end
  end

  def test_health_stale_fetched_at
    api = HomeAssistantConfigApi.new
    api.stub :last_fetched_at, "2023-08-27 15:14:59 -0600" do
      travel_to DateTime.new(2023, 8, 27, 16, 20, 0, "-0600") do
        refute(api.healthy?)
      end
    end
  end
end

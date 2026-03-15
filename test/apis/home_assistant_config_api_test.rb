# frozen_string_literal: true

require "test_helper"

class HomeAssistantConfigApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def teardown
    # Re-seed cache after tests that may overwrite it (e.g. test_fetch with VCR cassette)
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {
        last_fetched_at: Time.now.utc,
        response: {
          latitude: 38.4937,
          longitude: -98.7675,
          time_zone: "America/Chicago",
          unit_system: {
            temperature: "°F",
            wind_speed: "mph",
            accumulated_precipitation: "in"
          }
        }
      }.to_json
    )
  end

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
    api.stub :data, {time_zone: "America/Chicago"} do
      assert_equal("America/Chicago", api.time_zone)
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

  def test_url
    api = HomeAssistantConfigApi.new
    assert_equal "http://homeassistant.local:8123/api/config", api.url
  end

  def test_headers
    api = HomeAssistantConfigApi.new({"home_assistant_token" => "test_token"})
    headers = api.headers
    assert_equal "Bearer test_token", headers[:Authorization]
    assert_equal "application/json", headers[:"content-type"]
  end

  def test_unit_system_defaults
    api = HomeAssistantConfigApi.new
    api.stub :data, {} do
      assert_equal({}, api.unit_system)
      assert_equal "mph", api.ha_speed_unit
      assert_equal "F", api.ha_temperature_unit
      assert_equal "in", api.ha_precipitation_unit
    end
  end

  def test_unit_system_imperial
    api = HomeAssistantConfigApi.new
    api.stub :data, {unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}} do
      assert_equal "mph", api.ha_speed_unit
      assert_equal "F", api.ha_temperature_unit
      assert_equal "in", api.ha_precipitation_unit
    end
  end

  def test_unit_system_metric
    api = HomeAssistantConfigApi.new
    api.stub :data, {unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}} do
      assert_equal "kph", api.ha_speed_unit
      assert_equal "C", api.ha_temperature_unit
      assert_equal "mm", api.ha_precipitation_unit
    end
  end

  def test_unit_system_cm_precipitation
    api = HomeAssistantConfigApi.new
    api.stub :data, {unit_system: {accumulated_precipitation: "cm"}} do
      assert_equal "cm", api.ha_precipitation_unit
    end
  end
end

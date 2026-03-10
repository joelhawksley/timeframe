# frozen_string_literal: true

require "test_helper"

class WeatherKitApiTest < Minitest::Test
  def setup
    Rails.cache.delete(DEPLOY_TIME.to_s + "weather_kit_api")
  end

  def test_fetch_skips_when_tenkit_unconfigured
    Tenkit.stub :config, nil do
      api = WeatherKitApi.new
      assert_nil api.fetch
    end
  end

  def test_fetch_skips_when_team_id_blank
    config = Tenkit.config
    config.team_id = ""
    Tenkit.stub :config, config do
      api = WeatherKitApi.new
      assert_nil api.fetch
    end
  end

  def test_fetch_skips_when_key_blank
    config = Tenkit.config
    config.team_id = "test_team"
    config.key = ""
    Tenkit.stub :config, config do
      api = WeatherKitApi.new
      assert_nil api.fetch
    end
  end

  def test_fetch_saves_response
    weather_response = Minitest::Mock.new
    weather_response.expect(:raw, {"forecastNextHour" => {"summary" => []}})

    client = Minitest::Mock.new
    client.expect(:weather, weather_response, ["38.4937", "-98.7675"], data_sets: [:forecast_next_hour])

    config = Tenkit.config
    config.team_id = "test_team"
    config.key = "test_key"

    Tenkit.stub :config, config do
      Tenkit::Client.stub :new, client do
        api = WeatherKitApi.new
        api.fetch

        assert api.healthy?
        assert_equal({summary: []}, api.data[:forecastNextHour])
      end
    end
  end

  def test_not_healthy_without_data
    api = WeatherKitApi.new
    assert_equal false, api.healthy?
  end
end

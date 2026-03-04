# frozen_string_literal: true

require "test_helper"

class HomeAssistantWeatherApiTest < Minitest::Test
  def setup
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_weather_api")
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_api")
  end

  def test_fetch
    # Pre-populate HomeAssistantApi cache so weather entity can be discovered
    Rails.cache.write(
      DEPLOY_TIME.to_s + "home_assistant_api",
      {last_fetched_at: Time.now.utc, response: [{entity_id: "weather.honeysuckle_weather", state: "sunny", attributes: {attribution: "Powered by WeatherFlow https://weatherflow.com"}}]}.to_json
    )

    VCR.use_cassette(:home_assistant_weather) do
      api = HomeAssistantWeatherApi.new
      api.fetch

      assert api.healthy?
      assert api.hourly_forecast.length > 0
      assert api.daily_forecast.length > 0
      assert_equal "Powered by WeatherFlow", api.attribution
    end
  end

  def test_hourly_forecast_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.hourly_forecast
  end

  def test_daily_forecast_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.daily_forecast
  end

  def test_hourly_calendar_events_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.hourly_calendar_events
  end

  def test_hourly_calendar_events
    VCR.use_cassette(:home_assistant_weather) do
      api = HomeAssistantWeatherApi.new
      api.fetch

      events = api.hourly_calendar_events
      # May be empty if cassette hours don't align with sample times,
      # but should not raise
      assert events.is_a?(Array)
    end
  end

  def test_icon_for
    api = HomeAssistantWeatherApi.new
    assert_equal "cloud", api.icon_for("cloudy")
    assert_equal "weather-sunny", api.icon_for("sunny")
    assert_equal "weather-rainy", api.icon_for("rainy")
    assert_equal "snowflake", api.icon_for("snowy")
    assert_equal "help-circle", api.icon_for("unknown-condition")
  end
end

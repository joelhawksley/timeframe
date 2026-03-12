# frozen_string_literal: true

require "test_helper"

class HomeAssistantWeatherApiTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

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

  def test_hourly_calendar_events_with_data
    travel_to DateTime.new(2023, 8, 27, 12, 0, 0, "-0600") do
      today = Date.new(2023, 8, 27)
      noon_utc = today.in_time_zone("America/Chicago").noon.utc.iso8601

      api = HomeAssistantWeatherApi.new
      api.stub :hourly_forecast, [{datetime: noon_utc, condition: "sunny", temperature: 85}] do
        events = api.hourly_calendar_events
        assert events.length > 0
        assert_equal "85°", events.first.summary
        assert_equal "weather-sunny", events.first.icon
      end
    end
  end

  def test_daily_calendar_events_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.daily_calendar_events
  end

  def test_daily_calendar_events_with_data
    api = HomeAssistantWeatherApi.new
    api.stub :daily_forecast, [
      {datetime: "2023-08-27T06:00:00Z", condition: "sunny", temperature: 90, templow: 65}
    ] do
      events = api.daily_calendar_events
      assert_equal 1, events.length
      assert_equal "90° / 65°", events.first.summary
      assert_equal "weather-sunny", events.first.icon
    end
  end

  def test_precip_calendar_events_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.precip_calendar_events
  end

  def test_precip_calendar_events_with_rain
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 2.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain", events.first.summary
      assert_equal "weather-rainy", events.first.icon
    end
  end

  def test_precip_calendar_events_with_snow
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 2.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow", events.first.summary
      assert_equal "snowflake", events.first.icon
    end
  end

  def test_precip_calendar_events_merges_consecutive_hours
    hour1 = (Time.now + 1.hour).utc.beginning_of_hour
    hour2 = hour1 + 1.hour

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: hour1.iso8601, condition: "rainy", precipitation_probability: 80, precipitation: 2.0},
      {datetime: hour2.iso8601, condition: "rainy", precipitation_probability: 70, precipitation: 1.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
    end
  end

  def test_wind_calendar_events_returns_empty_when_no_data
    api = HomeAssistantWeatherApi.new
    assert_equal [], api.wind_calendar_events
  end

  def test_wind_calendar_events_with_high_wind
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 40.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 1, events.length
      assert_includes events.first.summary, "mph"
      assert_equal "arrow-up", events.first.icon
    end
  end

  def test_wind_calendar_events_skips_low_wind
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 10.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 0, events.length
    end
  end

  def test_wind_calendar_events_skips_past_hours
    past_time = (Time.now - 2.hours).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: past_time, wind_gust_speed: 40.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 0, events.length
    end
  end

  def test_wind_calendar_events_merges_consecutive_hours
    hour1 = (Time.now + 1.hour).utc.beginning_of_hour
    hour2 = hour1 + 1.hour

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: hour1.iso8601, wind_gust_speed: 40.0, wind_bearing: 180},
      {datetime: hour2.iso8601, wind_gust_speed: 50.0, wind_bearing: 90}
    ] do
      events = api.wind_calendar_events
      assert_equal 1, events.length
      assert_includes events.first.summary, "31" # 50 km/h * 0.621371 ≈ 31 mph
    end
  end

  def test_fetch_forecast_handles_network_error
    VCR.use_cassette(:home_assistant_weather) do
      api = HomeAssistantWeatherApi.new
      HTTParty.stub :post, ->(*) { raise Errno::ECONNREFUSED } do
        result = api.send(:fetch_forecast, "weather.test", "hourly")
        assert_nil result
      end
    end
  end

  def test_fetch_no_weather_entity
    api = HomeAssistantWeatherApi.new
    ha_api = HomeAssistantApi.new
    ha_api.stub :weather_entity_id, nil do
      HomeAssistantApi.stub :new, ha_api do
        assert_nil api.fetch
      end
    end
  end

  def test_fetch_no_forecast_data
    api = HomeAssistantWeatherApi.new
    ha_api = HomeAssistantApi.new
    ha_api.stub :weather_entity_id, "weather.test" do
      ha_api.stub :data, [] do
        HomeAssistantApi.stub :new, ha_api do
          api.stub :fetch_forecast, nil do
            assert_nil api.fetch
          end
        end
      end
    end
  end

  def test_attribution_nil
    api = HomeAssistantWeatherApi.new
    api.stub :data, {} do
      assert_nil api.attribution
    end
  end

  def test_precip_skips_low_probability
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 20, precipitation: 1.0}
    ] do
      assert_equal [], api.precip_calendar_events
    end
  end

  def test_precip_skips_zero_precip_moderate_probability
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 40, precipitation: 0.0}
    ] do
      assert_equal [], api.precip_calendar_events
    end
  end

  def test_precip_skips_past_hours
    past_time = (Time.now - 2.hours).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: past_time, condition: "rainy", precipitation_probability: 80, precipitation: 2.0}
    ] do
      assert_equal [], api.precip_calendar_events
    end
  end

  def test_wind_skips_past_hours
    past_time = (Time.now - 2.hours).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: past_time, wind_speed: 50.0, wind_bearing: 180}
    ] do
      assert_equal [], api.wind_calendar_events
    end
  end

  def test_fetch_entity_not_found_in_data
    api = HomeAssistantWeatherApi.new
    ha_api = HomeAssistantApi.new
    ha_api.stub :weather_entity_id, "weather.nonexistent" do
      ha_api.stub :data, [] do
        HomeAssistantApi.stub :new, ha_api do
          api.stub :fetch_forecast, [{}] do
            api.fetch
            assert api.data.present?
            assert_nil api.data[:attribution]
          end
        end
      end
    end
  end

  def test_fetch_forecast_non_200
    api = HomeAssistantWeatherApi.new
    response = Struct.new(:code).new(500)
    HTTParty.stub :post, response do
      result = api.send(:fetch_forecast, "weather.test", "hourly")
      assert_nil result
    end
  end
end

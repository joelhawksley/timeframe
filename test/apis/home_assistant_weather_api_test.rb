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
    # HA sends 2.0in, default precipitation_unit is "in" so no conversion
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 2.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 2.0\"", events.first.summary
      assert_equal "weather-rainy", events.first.icon
    end
  end

  def test_precip_calendar_events_with_snow
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    # HA sends 2.0in, default precipitation_unit is "in" so no conversion
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 2.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow 2.0\"", events.first.summary
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
      assert_includes events.first.summary, "50" # max of 40 and 50
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

  def test_wind_calendar_events_with_kph_unit
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    config = Timeframe::Application.config.local.dup
    config["speed_unit"] = "kph"
    api = HomeAssistantWeatherApi.new(config)
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 40.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 1, events.length
      assert_includes events.first.summary, "kph"
    end
  end

  def test_wind_calendar_events_kph_threshold
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    config = Timeframe::Application.config.local.dup
    config["speed_unit"] = "kph"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends in mph (seeded unit_system), 15mph = 24.1kph < 32 threshold
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 15.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 0, events.length
    end
  end

  def test_precip_calendar_events_zero_amount_high_probability
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 0.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain", events.first.summary
    end
  end

  def test_precip_small_amount
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    api = HomeAssistantWeatherApi.new
    # HA sends 0.05in, default precipitation_unit is "in"
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 0.05}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 0.1\"", events.first.summary
    end
  end

  def test_convert_speed_mph_to_kph
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    config = Timeframe::Application.config.local.dup
    config["speed_unit"] = "kph"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 25mph, converts to ~40.2kph which is above 32 threshold
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 25.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 1, events.length
      assert_includes events.first.summary, "40kph"
    end
  end

  def test_convert_speed_kph_to_mph
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with metric
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}}}.to_json
    )

    config = Timeframe::Application.config.local.dup
    config["speed_unit"] = "mph"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 50kph, converts to ~31mph which is above 20 threshold
    api.stub :hourly_forecast, [
      {datetime: future_time, wind_gust_speed: 50.0, wind_bearing: 180}
    ] do
      events = api.wind_calendar_events
      assert_equal 1, events.length
      assert_includes events.first.summary, "31mph"
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_rain_converts_in_to_mm
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 1.0in, rain converts to mm: 1.0 * 25.4 = 25.4mm
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 1.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 25.4mm", events.first.summary
    end
  end

  def test_precip_snow_converts_in_to_cm
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 1.0in, snow converts to cm: 1.0 * 2.54 = 2.5cm
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 1.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow 2.5cm", events.first.summary
    end
  end

  def test_precip_rain_from_mm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with metric mm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}}}.to_json
    )

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 25.4mm, rain stays in mm (no conversion needed)
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 25.4}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 25.4mm", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_snow_from_mm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with metric mm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}}}.to_json
    )

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 50mm, snow converts to cm: 50 / 10 = 5.0cm
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 50.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow 5.0cm", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_snow_from_cm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with cm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "cm"}}}.to_json
    )

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 5.0cm, snow stays in cm (no conversion needed)
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 5.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow 5.0cm", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_rain_from_cm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with cm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "cm"}}}.to_json
    )

    config = Timeframe::Application.config.local.dup
    config["precipitation_unit"] = "mm"
    api = HomeAssistantWeatherApi.new(config)
    # HA sends 5.0cm, rain converts to mm: 5.0 * 10 = 50.0mm
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 5.0}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 50.0mm", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_convert_precipitation_unknown_unit_passthrough
    api = HomeAssistantWeatherApi.new
    ha_config = api.send(:ha_config)
    ha_config.stub :ha_precipitation_unit, "liters" do
      assert_equal 5.0, api.send(:convert_precipitation, 5.0, "gallons")
    end
  end

  def test_convert_temperature_same_unit
    api = HomeAssistantWeatherApi.new
    # HA sends F, display unit is F (default) — no conversion
    api.stub :daily_forecast, [
      {datetime: "2023-08-27T06:00:00Z", condition: "sunny", temperature: 90, templow: 65}
    ] do
      events = api.daily_calendar_events
      assert_equal "90° / 65°", events.first.summary
    end
  end

  def test_convert_temperature_f_to_c
    config = Timeframe::Application.config.local.dup
    config["temperature_unit"] = "C"
    api = HomeAssistantWeatherApi.new(config)

    api.stub :daily_forecast, [
      {datetime: "2023-08-27T06:00:00Z", condition: "sunny", temperature: 90, templow: 68}
    ] do
      events = api.daily_calendar_events
      assert_equal "32° / 20°", events.first.summary
    end
  end

  def test_convert_temperature_c_to_f
    config = Timeframe::Application.config.local.dup
    config["temperature_unit"] = "F"
    api = HomeAssistantWeatherApi.new(config)

    # Seed HA config with Celsius
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}}}.to_json
    )

    api.stub :daily_forecast, [
      {datetime: "2023-08-27T06:00:00Z", condition: "sunny", temperature: 32, templow: 20}
    ] do
      events = api.daily_calendar_events
      assert_equal "90° / 68°", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_in_mode_with_mm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with metric mm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "mm"}}}.to_json
    )

    # precipitation_unit defaults to "in", HA sends mm
    api = HomeAssistantWeatherApi.new
    # HA sends 25.4mm, converts to 1.0in
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "rainy", precipitation_probability: 80, precipitation: 25.4}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Rain 1.0\"", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end

  def test_precip_in_mode_snow_with_cm_ha
    future_time = (Time.now + 1.hour).utc.beginning_of_hour.iso8601

    # Seed HA config with cm
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {time_zone: "America/Chicago", unit_system: {temperature: "°C", wind_speed: "km/h", accumulated_precipitation: "cm"}}}.to_json
    )

    # precipitation_unit defaults to "in", HA sends cm
    api = HomeAssistantWeatherApi.new
    # HA sends 2.54cm, converts to 1.0in
    api.stub :hourly_forecast, [
      {datetime: future_time, condition: "snowy", precipitation_probability: 80, precipitation: 2.54}
    ] do
      events = api.precip_calendar_events
      assert_equal 1, events.length
      assert_equal "Snow 1.0\"", events.first.summary
    end
  ensure
    Rails.cache.write(
      "#{DEPLOY_TIME}home_assistant_config_api",
      {last_fetched_at: Time.now.utc, response: {latitude: 38.4937, longitude: -98.7675, time_zone: "America/Chicago", unit_system: {temperature: "°F", wind_speed: "mph", accumulated_precipitation: "in"}}}.to_json
    )
  end
end

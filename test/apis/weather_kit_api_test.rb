# frozen_string_literal: true

require "test_helper"

class WeatherKitApiTest < Minitest::Test
  def setup
    @store = ActiveSupport::Cache::MemoryStore.new
    @location = test_location
    @api = WeatherKitApi.new(location: @location, store: @store)
  end

  def test_weather_healthy_returns_false_with_no_data
    assert_equal false, @api.weather_healthy?
  end

  def test_weather_healthy_returns_true_with_fresh_data
    seed_weather_data
    assert @api.weather_healthy?
  end

  def test_current_temperature_converts_celsius_to_fahrenheit
    seed_weather_data(current_weather: {temperature: 20.0, temperature_apparent: 18.0})
    assert_equal "64°", @api.current_temperature
  end

  def test_current_temperature_returns_celsius_when_configured
    api = WeatherKitApi.new(location: @location, store: @store, temperature_unit: "C")
    seed_weather_data(current_weather: {temperature: 20.0, temperature_apparent: 18.0})
    assert_equal "18°", api.current_temperature
  end

  def test_current_temperature_returns_nil_without_data
    assert_nil @api.current_temperature
  end

  def test_attribution
    assert_equal "Apple Weather", @api.attribution
  end

  def test_time_zone
    assert_equal "America/Chicago", @api.time_zone
  end

  def test_hourly_calendar_events_returns_display_events
    today = Date.today.in_time_zone("America/Chicago")
    noon = today.noon

    seed_weather_data(hourly: [
      {datetime: noon.utc.iso8601, temperature: 22.0, condition: "Clear"}
    ])

    events = @api.hourly_calendar_events
    assert events.any?

    event = events.first
    assert_equal "72°", event.summary
    assert_equal "weather-sunny", event.icon
  end

  def test_daily_calendar_events_returns_display_events
    today = Date.today.in_time_zone("America/Chicago")

    seed_weather_data(daily: [
      {datetime: today.beginning_of_day.utc.iso8601, condition: "PartlyCloudy", temperature_max: 30.0, temperature_min: 18.0}
    ])

    events = @api.daily_calendar_events
    assert_equal 1, events.size

    event = events.first
    assert_equal "86° / 64°", event.summary
    assert_equal "weather-partly-cloudy", event.icon
  end

  def test_precip_calendar_events_groups_consecutive_hours
    future = (Time.now + 2.hours).beginning_of_hour
    h1 = future.utc.iso8601
    h2 = (future + 1.hour).utc.iso8601

    seed_weather_data(hourly: [
      {datetime: h1, condition: "Rain", precipitation_chance: 0.8, precipitation_amount: 2.5, wind_speed: 5, wind_gust: 5, wind_direction: 0},
      {datetime: h2, condition: "Rain", precipitation_chance: 0.6, precipitation_amount: 1.5, wind_speed: 5, wind_gust: 5, wind_direction: 0}
    ])

    events = @api.precip_calendar_events
    assert_equal 1, events.size
    assert_includes events.first.summary, "Rain"
    assert_equal "weather-rainy", events.first.icon
  end

  def test_wind_calendar_events_with_high_gusts
    future = (Time.now + 2.hours).beginning_of_hour
    h1 = future.utc.iso8601

    # wind_gust is in m/s, threshold is 20mph = ~32kph = ~8.9 m/s
    seed_weather_data(hourly: [
      {datetime: h1, condition: "Clear", precipitation_chance: 0, precipitation_amount: 0, wind_speed: 5, wind_gust: 15.0, wind_direction: 180}
    ])

    events = @api.wind_calendar_events
    assert_equal 1, events.size
    assert_includes events.first.summary, "Gusts up to"
    assert_equal "arrow-up", events.first.icon
    assert_equal 180, events.first.icon_rotation
  end

  def test_wind_calendar_events_skips_low_gusts
    future = (Time.now + 2.hours).beginning_of_hour
    h1 = future.utc.iso8601

    seed_weather_data(hourly: [
      {datetime: h1, condition: "Clear", precipitation_chance: 0, precipitation_amount: 0, wind_speed: 2, wind_gust: 3.0, wind_direction: 90}
    ])

    events = @api.wind_calendar_events
    assert_empty events
  end

  def test_weather_alert_events
    seed_weather_data(alerts: [
      {id: "alert-1", description: "Heat Advisory", effective_time: "2026-03-31T08:00:00Z", expire_time: "2026-03-31T20:00:00Z", severity: "minor", source: "NWS"}
    ])

    events = @api.weather_alert_events
    assert_equal 1, events.size
    assert_equal "Heat Advisory", events.first.summary
    assert_equal "alert", events.first.icon
  end

  def test_weather_alert_events_returns_empty_without_alerts
    seed_weather_data(alerts: [])
    assert_empty @api.weather_alert_events
  end

  def test_condition_icons_map_known_conditions
    %w[Clear MostlyClear PartlyCloudy Cloudy Rain HeavyRain Snow Thunderstorms Foggy Windy].each do |code|
      refute_equal "help-circle", WeatherKitApi::CONDITION_ICONS[code], "Missing icon for #{code}"
    end
  end

  def test_condition_icons_returns_help_circle_for_unknown
    api = WeatherKitApi.new(location: @location, store: @store)
    seed_weather_data(hourly: [
      {datetime: Date.today.in_time_zone("America/Chicago").noon.utc.iso8601, temperature: 20.0, condition: "UnknownCondition"}
    ])
    events = api.hourly_calendar_events
    event = events.find { |e| e.icon == "help-circle" }
    assert event, "Unknown conditions should use help-circle icon"
  end

  def test_fetch_weather_handles_errors_gracefully
    api = WeatherKitApi.new(location: @location, store: @store)
    Tenkit::Client.stub(:new, -> { raise "connection failed" }) do
      api.fetch_weather
    end
    refute api.weather_healthy?
  end

  def test_precip_events_with_metric_units
    api = WeatherKitApi.new(location: @location, store: @store, precipitation_unit: "mm")
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 5.0, condition: "Rain", precipitation_chance: 0.8, precipitation_amount: 5.0},
      {datetime: (now + 1.hour).utc.iso8601, temperature: 5.0, condition: "Rain", precipitation_chance: 0.8, precipitation_amount: 3.0}
    ])
    events = api.precip_calendar_events
    assert events.any?
  end

  def test_precip_events_with_snow_metric
    api = WeatherKitApi.new(location: @location, store: @store, precipitation_unit: "mm")
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: -5.0, condition: "Snow", precipitation_chance: 0.8, precipitation_amount: 10.0}
    ])
    events = api.precip_calendar_events
    assert events.any?
    assert events.first.icon == "snowflake"
  end

  def test_precip_events_with_zero_amount
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 5.0, condition: "Rain", precipitation_chance: 0.8, precipitation_amount: 0.0}
    ])
    events = @api.precip_calendar_events
    assert events.any?
    assert_includes events.first.summary, "Rain"
    refute_includes events.first.summary, "0"
  end

  def test_wind_events_groups_consecutive_hours
    api = WeatherKitApi.new(location: @location, store: @store, speed_unit: "mph")
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 20.0, condition: "Windy", wind_gust: 50.0, wind_direction: 180},
      {datetime: (now + 1.hour).utc.iso8601, temperature: 20.0, condition: "Windy", wind_gust: 60.0, wind_direction: 270}
    ])
    events = api.wind_calendar_events
    # Consecutive hours should be grouped into one event
    assert_equal 1, events.length
    assert_includes events.first.summary, "mph"
  end

  def test_wind_events_with_kph_units
    api = WeatherKitApi.new(location: @location, store: @store, speed_unit: "kph")
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 20.0, condition: "Windy", wind_gust: 50.0, wind_direction: 180}
    ])
    events = api.wind_calendar_events
    assert events.any?
  end

  def test_wind_events_skips_low_gusts_kph
    api = WeatherKitApi.new(location: @location, store: @store, speed_unit: "kph")
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 20.0, condition: "Clear", wind_gust: 5.0, wind_direction: 90}
    ])
    events = api.wind_calendar_events
    assert_empty events
  end

  def test_convert_speed_kph
    api = WeatherKitApi.new(location: @location, store: @store, speed_unit: "kph")
    # Speed should stay as kph
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 20.0, condition: "Windy", wind_gust: 50.0, wind_direction: 270}
    ])
    events = api.wind_calendar_events
    assert events.any?
    assert_includes events.first.summary, "kph"
  end

  def test_daily_calendar_events_with_data
    now = Date.today.in_time_zone("America/Chicago")
    seed_weather_data(daily: [
      {datetime: now.iso8601, temperature_min: 10.0, temperature_max: 25.0, condition: "Clear"}
    ])
    events = @api.daily_calendar_events
    assert events.any?
  end

  def test_hourly_events_returns_empty_without_data
    assert_empty @api.hourly_calendar_events
  end

  def test_daily_events_returns_empty_without_data
    assert_empty @api.daily_calendar_events
  end

  def test_precip_events_returns_empty_without_data
    assert_empty @api.precip_calendar_events
  end

  def test_wind_events_returns_empty_without_data
    assert_empty @api.wind_calendar_events
  end

  def test_current_temperature_with_no_current_weather
    seed_weather_data(current_weather: nil)
    assert_nil @api.current_temperature
  end

  def test_hourly_events_with_healthy_but_empty_hourly
    seed_weather_data(hourly: [])
    assert_empty @api.hourly_calendar_events
  end

  def test_daily_events_with_healthy_but_empty_daily
    seed_weather_data(daily: [])
    assert_empty @api.daily_calendar_events
  end

  def test_precip_events_groups_consecutive_rain_hours
    now = 1.day.from_now.in_time_zone("America/Chicago").noon
    seed_weather_data(hourly: [
      {datetime: now.utc.iso8601, temperature: 15.0, condition: "Rain", precipitation_chance: 0.8, precipitation_amount: 2.0},
      {datetime: (now + 1.hour).utc.iso8601, temperature: 15.0, condition: "Rain", precipitation_chance: 0.7, precipitation_amount: 3.0}
    ])
    events = @api.precip_calendar_events
    assert_equal 1, events.length
  end

  private

  def seed_weather_data(current_weather: {temperature: 20.0, temperature_apparent: 18.0}, hourly: [], daily: [], alerts: [])
    data = {
      current_weather: current_weather,
      hourly: hourly,
      daily: daily,
      alerts: alerts
    }
    @store.write(
      "#{DEPLOY_TIME}#{WeatherKitApi::CACHE_DOMAIN}_#{@location.id}",
      {last_fetched_at: Time.now.utc, response: data}.to_json
    )
  end
end

scheduler = Rufus::Scheduler.new

timeframe_config = TimeframeConfig.new

if timeframe_config.home_assistant?
  api = HomeAssistantApi.new
  api.fetch_states
  api.fetch_config
  api.fetch_calendars
  api.fetch_weather

  scheduler.every "2s" do
    HomeAssistantApi.new.fetch_states
  end

  scheduler.every "1m" do
    HomeAssistantApi.new.fetch_config
  end

  scheduler.every "1m" do
    HomeAssistantApi.new.fetch_calendars
  end

  scheduler.every "1m" do
    HomeAssistantApi.new.fetch_weather
  end
elsif timeframe_config.weatherkit?
  scheduler.every "1m" do
    Location.find_each do |location|
      WeatherKitApi.new(location: location).fetch_weather
    rescue => e
      Rails.logger.error "[WeatherKit Scheduler] #{location.name}: #{e.message}"
    end
  end

  scheduler.in "5s" do
    Location.find_each do |location|
      WeatherKitApi.new(location: location).fetch_weather
    rescue => e
      Rails.logger.error "[WeatherKit Scheduler] #{location.name}: #{e.message}"
    end
  end
end

scheduler.every "15m" do
  Device.refresh_all_screenshots!
end

scheduler.in "30s" do
  Device.refresh_all_screenshots!
end

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

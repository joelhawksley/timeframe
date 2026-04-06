scheduler = Rufus::Scheduler.new

timeframe_config = TimeframeConfig.new

if timeframe_config.home_assistant?
  api = HomeAssistantApi.new
  api.fetch_config
  api.fetch_calendars
  api.fetch_weather

  # Start WebSocket client for real-time state updates (replaces 2s polling)
  Thread.new do
    HomeAssistantWebSocket.new.start
  rescue => e
    Rails.logger.error "[HA WebSocket] Thread error: #{e.message}"
  end

  scheduler.every "30s" do
    api = HomeAssistantApi.new
    unless api.states_healthy?
      api.fetch_states
      DisplayBroadcaster.broadcast_all_mira_displays
    end
  end

  scheduler.every "5m" do
    HomeAssistantApi.new.fetch_config
    DisplayBroadcaster.broadcast_all_mira_displays
  end

  scheduler.every "15m" do
    HomeAssistantApi.new.fetch_calendars
    DisplayBroadcaster.broadcast_all_mira_displays
  end

  scheduler.every "15m" do
    HomeAssistantApi.new.fetch_weather
    DisplayBroadcaster.broadcast_all_mira_displays
  end
elsif timeframe_config.weatherkit?
  scheduler.every "15m" do
    Location.find_each do |location|
      WeatherKitApi.new(location: location).fetch_weather
    rescue => e
      Rails.logger.error "[WeatherKit Scheduler] #{location.name}: #{e.message}"
    end
    DisplayBroadcaster.broadcast_all_mira_displays
  end

  scheduler.in "5s" do
    Location.find_each do |location|
      WeatherKitApi.new(location: location).fetch_weather
    rescue => e
      Rails.logger.error "[WeatherKit Scheduler] #{location.name}: #{e.message}"
    end
    DisplayBroadcaster.broadcast_all_mira_displays
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

scheduler = Rufus::Scheduler.new

api = HomeAssistantApi.new
api.fetch_config

# Start WebSocket client for real-time state updates via subscribe_entities
ha_websocket = HomeAssistantWebSocket.new
Thread.new do
  ha_websocket.start
rescue => e
  Rails.logger.error "[HA WebSocket] Thread error: #{e.message}"
end

# Fetch calendars and weather after WebSocket has populated states
scheduler.in "5s" do
  api = HomeAssistantApi.new
  api.fetch_calendars
  api.fetch_weather
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.every "1m" do
  api = HomeAssistantApi.new
  api.fetch_states
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.every "5m" do
  HomeAssistantApi.new.fetch_config
  ha_websocket.refresh_entities!
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

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

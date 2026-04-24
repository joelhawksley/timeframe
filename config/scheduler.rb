scheduler = Rufus::Scheduler.new

api = HomeAssistantApi.new
api.fetch_config

# Fetch states every 2 seconds for near-real-time updates
scheduler.every "2s" do
  HomeAssistantApi.new.fetch_states
  DisplayBroadcaster.broadcast_all_mira_displays
end

# Fetch calendars and weather on startup
scheduler.in "5s" do
  api = HomeAssistantApi.new
  api.fetch_calendars
  api.fetch_weather
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.every "5m" do
  HomeAssistantApi.new.fetch_config
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.every "1m" do
  HomeAssistantApi.new.fetch_calendars
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.every "1m" do
  HomeAssistantApi.new.fetch_weather
  DisplayBroadcaster.broadcast_all_mira_displays
end

scheduler.join

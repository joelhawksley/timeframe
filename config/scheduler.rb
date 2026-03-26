scheduler = Rufus::Scheduler.new

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

scheduler.every "15m" do
  Device.refresh_all_screenshots!
end

scheduler.in "30s" do
  Device.refresh_all_screenshots!
end

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

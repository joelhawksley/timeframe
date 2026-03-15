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

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

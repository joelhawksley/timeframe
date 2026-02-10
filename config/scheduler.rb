scheduler = Rufus::Scheduler.new

scheduler.every "2s" do
  HomeAssistantApi.new(Timeframe::Application.config.local).fetch
end

scheduler.every "1m" do
  HomeAssistantCalendarApi.new(Timeframe::Application.config.local).fetch
end

scheduler.every "1m" do
  WeatherKitApi.new.fetch
end

scheduler.every "1m" do
  AirNowApi.new.fetch
end

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

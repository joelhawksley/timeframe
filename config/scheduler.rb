scheduler = Rufus::Scheduler.new

def fetch_weather
  api = HomeAssistantApi.new
  api.fetch_config
  api.fetch_weather
end

def fetch_calendar
  HomeAssistantApi.new.fetch_calendars
end

fetch_weather
fetch_calendar

scheduler.every "2s" do
  HomeAssistantApi.new.fetch_states
end

scheduler.every "1m" do
  fetch_calendar
end

scheduler.every "1m" do
  fetch_weather
end

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

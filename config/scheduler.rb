scheduler = Rufus::Scheduler.new

def fetch_weather
  config_api = HomeAssistantConfigApi.new
  config_api.fetch
  HomeAssistantWeatherApi.new.fetch
end

def fetch_calendar
  HomeAssistantCalendarApi.new.fetch
end

fetch_weather
fetch_calendar

scheduler.every "2s" do
  HomeAssistantApi.new.fetch
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

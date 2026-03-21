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
  base_url = "http://localhost:#{ENV.fetch("PORT", 80)}"
  Device.where(model: "trmnl_og").find_each do |device|
    device.refresh_screenshot!(base_url)
  rescue => e
    Rails.logger.error "[Screenshot] Failed for #{device.name}: #{e.message}"
  end
end

# This will attach scheduler thread to Puma's background thread.
# Dont forget to add this line!
scheduler.join

class ScheduleJob < ActiveJob::Base
  def perform(task)
    case task.to_sym
    when :sonos
      SonosApi.fetch
    when :home_assistant
      HomeAssistantApi.fetch
    when :weather_kit
      WeatherKitApi.fetch
    when :google_calendar
      GoogleCalendarApi.fetch
    when :birdnet
      BirdnetApi.fetch
    end
  end
end
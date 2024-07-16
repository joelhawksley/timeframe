class ScheduleJob < ActiveJob::Base
  queue_as :default

  def perform(task)
    puts "Running #{task} task"

    case task.to_sym
    when :sonos
      SonosApi.new.fetch
    when :home_assistant
      HomeAssistantApi.new.fetch
    when :weather_kit
      WeatherKitApi.new.fetch
    when :google_calendar
      GoogleCalendarApi.new.fetch
    when :birdnet
      BirdnetApi.new.fetch
    when :airnow
      AirNowApi.new.fetch
    end
  end
end

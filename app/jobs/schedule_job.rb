class ScheduleJob < ActiveJob::Base
  queue_as :default

  def perform(task)
    puts "Running #{task} task"

    case task.to_sym
    when :home_assistant
      HomeAssistantApi.new(Timeframe::Application.config.local).fetch
    when :home_assistant_calendar
      HomeAssistantCalendarApi.new(Timeframe::Application.config.local).fetch
    when :home_assistant_lightning
      HomeAssistantLightningApi.new(Timeframe::Application.config.local).fetch
    when :weather_kit
      WeatherKitApi.new.fetch
    when :birdnet
      BirdnetApi.new.fetch
    when :airnow
      AirNowApi.new.fetch
    end
  end
end

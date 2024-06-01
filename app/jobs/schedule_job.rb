require "litestack"

class ScheduleJob
  include ::Litejob

  queue = :default

  def perform(task)
    case task.to_sym
    when :sonos
      SonosApi.fetch
    when :home_assistant
      HomeAssistantApi.fetch
    when :weather_kit
      WeatherKitApi.fetch
    when :google_calendar
      GoogleAccount.all.each(&:fetch)
    when :birdnet
      BirdnetApi.fetch
    when :dog_park
      DogParkApi.fetch
    end
  end
end
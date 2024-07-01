# :nocov:
unless Rails.env.test?
  Sidekiq::Options[:cron_poll_interval] = 1

  Sidekiq::Cron::Job.create(
    name: "Fetch Sonos",
    cron: "every 2 seconds",
    args: ["sonos"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Home Assistant",
    cron: "every 2 seconds",
    args: ["home_assistant"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch WeatherKit",
    cron: "*/1 * * * *",
    args: ["weather_kit"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Google Calendar",
    cron: "*/1 * * * *",
    args: ["google_calendar"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Birdnet",
    cron: "*/1 * * * *",
    args: ["birdnet"],
    class: "ScheduleJob"
  )
end
# :nocov:

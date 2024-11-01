# :nocov:
unless Rails.env.test?
  Sidekiq::Options[:cron_poll_interval] = 1

  Sidekiq::Cron::Job.create(
    name: "Fetch Home Assistant",
    cron: "every 2 seconds",
    args: ["home_assistant"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Home Assistant Calendar",
    cron: "every 1 minute",
    args: ["home_assistant_calendar"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Home Assistant Lightning",
    cron: "every 1 minute",
    args: ["home_assistant_lightning"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch WeatherKit",
    cron: "*/1 * * * *",
    args: ["weather_kit"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Birdnet",
    cron: "*/1 * * * *",
    args: ["birdnet"],
    class: "ScheduleJob"
  )

  Sidekiq::Cron::Job.create(
    name: "Fetch Airnow",
    cron: "*/1 * * * *",
    args: ["airnow"],
    class: "ScheduleJob"
  )
end
# :nocov:

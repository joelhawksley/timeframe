require "schedule_job"

scheduler = Rufus::Scheduler.new

if ENV["RUN_BG"] || ENV["RAILS_ENV"] == "production"
  scheduler.every "1s" do
    ScheduleJob.perform_async(:sonos)
  end

  scheduler.every "1s" do
    ScheduleJob.perform_async(:home_assistant)
  end

  scheduler.every "1m", first: :now do
    ScheduleJob.perform_async(:weather_kit)
  end

  scheduler.every "1m", first: :now do
    ScheduleJob.perform_async(:google_calendar)
  end

  scheduler.every "5m", first: :now do
    ScheduleJob.perform_async(:birdnet)
  end

  scheduler.every "5m", first: :now do
    ScheduleJob.perform_async(:dog_park)
  end
end

scheduler.join
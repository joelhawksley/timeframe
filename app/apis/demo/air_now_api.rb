module Demo
  class AirNowApi < Demo::Api
    def daily_calendar_events
      [
        CalendarEvent.new(
          id: "_air_now",
          starts_at: Date.today.in_time_zone(Timeframe::Application.config.local["timezone"]),
          ends_at: Date.today.in_time_zone(Timeframe::Application.config.local["timezone"]) + 1.day,
          icon: "triangle-exclamation",
          summary: "PM2.5 Unhealthy"
        )
      ]
    end
  end
end

module Demo
  class HomeAssistantCalendarApi < Demo::Api
    def data
      [
        CalendarEvent.new(
          id: SecureRandom.uuid,
          starts_at: (Time.now - 1.hour).beginning_of_hour.in_time_zone(Timeframe::Application.config.local["timezone"]),
          ends_at: (Time.now + 2.hours).beginning_of_hour.in_time_zone(Timeframe::Application.config.local["timezone"]),
          icon: "J",
          summary: "Smart Home Solver demo"
        ),
        CalendarEvent.new(
          id: SecureRandom.uuid,
          starts_at: DateTime.now.in_time_zone(Timeframe::Application.config.local["timezone"]).beginning_of_day,
          ends_at: DateTime.tomorrow.in_time_zone(Timeframe::Application.config.local["timezone"]).beginning_of_day,
          icon: "J",
          summary: "Smart Home Solver tour"
        ),
        CalendarEvent.new(
          id: SecureRandom.uuid,
          starts_at: DateTime.now.in_time_zone(Timeframe::Application.config.local["timezone"]).beginning_of_day,
          ends_at: DateTime.tomorrow.in_time_zone(Timeframe::Application.config.local["timezone"]).beginning_of_day,
          icon: "birthday-cake",
          summary: "Reed",
          description: "1980"
        )
      ]
    end

    def private_mode?
      false
    end
  end
end

class DisplayContent
  def call(
    weather_kit_api: nil,
    calendar_feed: CalendarFeed.new,
    timezone: "UTC",
    calendar_events: [],
    current_time: nil
  )
    current_time ||= Time.now.utc.in_time_zone(timezone)

    out = {}
    out[:top_left] = []
    out[:top_right] = []
    out[:weather_status] = []
    out[:current_time] = current_time
    out[:timestamp] = current_time.strftime("%-l:%M %p")

    raw_events = []

    if weather_kit_api&.weather_healthy?
      raw_events << weather_kit_api.hourly_calendar_events
      raw_events << weather_kit_api.daily_calendar_events
      raw_events << weather_kit_api.precip_calendar_events
      raw_events << weather_kit_api.wind_calendar_events
      raw_events << weather_kit_api.weather_alert_events
      out[:attribution] = weather_kit_api.attribution
      out[:current_temperature] = weather_kit_api.current_temperature
    end

    # Convert CalendarEvent records to DisplayEvent objects
    calendar_events.each do |ce|
      raw_events << DisplayEvent.new(
        starts_at: ce.starts_at,
        ends_at: ce.ends_at,
        summary: ce.title || "",
        description: ce.description,
        location: ce.location,
        timezone: timezone
      )
    end

    out[:private_mode] = false

    out[:day_groups] =
      (0...5).to_a.map do |day_index|
        date = current_time + day_index.day

        day_name =
          case day_index
          when 0
            "Today"
          when 1
            "Tomorrow"
          else
            date.strftime("%A")
          end

        events = calendar_feed.events_for(
          (day_index.zero? ? current_time : date.beginning_of_day).utc,
          date.end_of_day.utc,
          raw_events.flatten,
          false
        )

        if day_index.zero? && current_time.hour >= 20
          next if events[:periodic].empty? ||
            events[:periodic].all? { it.ends_at > date.end_of_day.utc }
        end

        show_daily = (day_index.zero? && current_time.hour < 20) || !day_index.zero?

        {
          day_name: day_name,
          date: date.to_date,
          show_daily: show_daily,
          daily: events[:daily].map { |e| e.as_json(date: date.to_date) },
          periodic: events[:periodic].map { |e| e.as_json(date: date.to_date) }
        }
      end.compact

    out
  end
end

class DisplayContent
  def call(
    home_assistant_api: HomeAssistantApi.new,
    weather_kit_api: nil,
    calendar_feed: CalendarFeed.new,
    current_time: nil
  )
    current_time ||= Time.now.utc.in_time_zone(home_assistant_api.time_zone)

    out = {}
    out[:top_left] = []
    out[:top_right] = []
    out[:weather_status] = []
    out[:current_time] = current_time
    out[:timestamp] = current_time.strftime("%-l:%M %p")

    if home_assistant_api.states_healthy?
      out[:current_temperature] = home_assistant_api.feels_like_temperature

      out[:now_playing] = home_assistant_api.now_playing
      out[:top_right] = home_assistant_api.top_right
      out[:top_left] = home_assistant_api.top_left
      out[:weather_status] = home_assistant_api.weather_status
    elsif TimeframeConfig.new.home_assistant?
      out[:top_left] << {icon: "alert", label: "Home Assistant"}
    end

    raw_events = []

    if weather_kit_api&.weather_healthy?
      raw_events << weather_kit_api.hourly_calendar_events
      raw_events << weather_kit_api.daily_calendar_events
      raw_events << weather_kit_api.precip_calendar_events
      raw_events << weather_kit_api.wind_calendar_events
      raw_events << weather_kit_api.weather_alert_events
      out[:attribution] = weather_kit_api.attribution
      out[:current_temperature] ||= weather_kit_api.current_temperature
    elsif home_assistant_api.weather_healthy?
      raw_events << home_assistant_api.hourly_calendar_events
      raw_events << home_assistant_api.daily_calendar_events
      raw_events << home_assistant_api.precip_calendar_events
      raw_events << home_assistant_api.wind_calendar_events
      out[:attribution] = home_assistant_api.attribution
    end

    if home_assistant_api.states_healthy?
      raw_events << home_assistant_api.daily_events(current_time: current_time)
    end

    private_mode = home_assistant_api.calendars_healthy? && home_assistant_api.private_mode?

    if private_mode
      out[:top_left] << {icon: "eye-off", label: "Private mode"}
    end

    out[:private_mode] = private_mode

    raw_events << home_assistant_api.calendar_events

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
          private_mode
        )

        # Attempt to hide Today if it's after 8pm and there are no events
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

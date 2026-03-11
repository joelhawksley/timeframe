class DisplayContent
  def call(
    current_time: Time.now.utc.in_time_zone(HomeAssistantConfigApi.new.time_zone),
    calendar_feed: CalendarFeed.new,
    home_assistant_api: HomeAssistantApi.new,
    home_assistant_calendar_api: HomeAssistantCalendarApi.new,
    home_assistant_weather_api: HomeAssistantWeatherApi.new
  )
    out = {}
    out[:top_left] = []
    out[:top_right] = []
    out[:weather_status] = []
    out[:current_time] = current_time
    out[:timestamp] = current_time.strftime("%-l:%M %p")

    if home_assistant_api.healthy?
      out[:current_temperature] = home_assistant_api.feels_like_temperature

      out[:now_playing] = home_assistant_api.now_playing
      out[:top_right] = home_assistant_api.top_right
      out[:top_left] = home_assistant_api.top_left
      out[:weather_status] = home_assistant_api.weather_status
    else
      out[:top_left] << {icon: "alert", label: "Home Assistant"}
    end

    raw_events = []

    if home_assistant_weather_api.healthy?
      raw_events << home_assistant_weather_api.hourly_calendar_events
      raw_events << home_assistant_weather_api.daily_calendar_events
      raw_events << home_assistant_weather_api.precip_calendar_events
      raw_events << home_assistant_weather_api.wind_calendar_events
      out[:attribution] = home_assistant_weather_api.attribution
    end

    if home_assistant_api.healthy?
      raw_events << home_assistant_api.daily_events(current_time: current_time)
    end

    if home_assistant_calendar_api.healthy? && home_assistant_calendar_api.private_mode?
      out[:top_left] << {icon: "eye-off", label: "Private mode"}
    end

    raw_events << home_assistant_calendar_api.data

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
          home_assistant_calendar_api.private_mode?
        )

        # Attempt to hide Today if it's after 8pm and there are no events
        if day_index.zero? && current_time.hour >= 20
          next if events[:periodic].empty? ||
            events[:periodic].all? { it.ends_at > date.end_of_day.utc }
        end

        {
          day_name: day_name,
          date: date.to_date,
          events: events,
          is_today: day_index.zero?
        }
      end.compact

    out
  end
end

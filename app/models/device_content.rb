class DeviceContent
  def call(
    device: nil,
    home_assistant_api: HomeAssistantApi.new,
    calendar_feed: CalendarFeed.new,
    timezone: nil,
    current_time: nil,
    days: 5,
    include_precip: true,
    include_wind: true,
    use_day_names: false,
    include_daily_weather: true,
    weather_row: false,
    start_time_only: false
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
    else
      out[:top_left] << {icon: "alert", label: "Home Assistant"}
    end

    raw_events = []

    if home_assistant_api.weather_healthy?
      raw_events << home_assistant_api.hourly_calendar_events
      raw_events << home_assistant_api.daily_calendar_events if include_daily_weather
      raw_events << home_assistant_api.precip_calendar_events if include_precip
      raw_events << home_assistant_api.wind_calendar_events if include_wind
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
      (0...days).to_a.map do |day_index|
        date = current_time + day_index.day

        day_name =
          if use_day_names
            date.strftime("%A")
          else
            case day_index
            when 0
              "Today"
            when 1
              "Tomorrow"
            else
              date.strftime("%A")
            end
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

        periodic_events = events[:periodic]
        weather_row_data = nil

        if weather_row
          if day_index.zero?
            all_day_events = calendar_feed.events_for(
              date.beginning_of_day.utc,
              date.end_of_day.utc,
              raw_events.flatten,
              false
            )
            weather_events = all_day_events[:periodic].select(&:weather?)
          else
            weather_events, _ = periodic_events.partition(&:weather?)
          end
          periodic_events = periodic_events.reject(&:weather?)
          weather_events = weather_events.select { |e| e.weather_hourly? && [8, 12, 16].include?(e.starts_at.hour) }
          weather_row_data = weather_events.map { |e| e.as_json(date: date.to_date) }
        end

        {
          day_name: day_name,
          date: date.to_date,
          show_daily: show_daily,
          daily: events[:daily].map { |e| e.as_json(date: date.to_date) },
          periodic: periodic_events.map { |e| e.as_json(date: date.to_date) },
          weather_row: weather_row_data
        }
      end.compact

    out[:start_time_only] = start_time_only

    out
  end
end

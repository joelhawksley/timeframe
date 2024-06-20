class DisplayContent
  def call
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    weather_kit_api = WeatherKitApi.new
    google_calendar_api = GoogleCalendarApi.new
    calendar_feed = CalendarFeed.new
    home_assistant_api = HomeAssistantApi.new
    birdnet_api = BirdnetApi.new
    sonos_api = SonosApi.new

    # :nocov:
    out = {}
    out[:status_icons] = []
    out[:status_icons_with_labels] = []
    out[:timestamp] = current_time.strftime("%-l:%M %p")
    out[:current_temperature] = home_assistant_api.feels_like_temperature
    raw_events = [[calendar_feed.baby_age_event]]

    if home_assistant_api.healthy?
      out[:status_icons] << "box-open" if home_assistant_api.package_present?
      out[:status_icons] << "garage-open" if home_assistant_api.garage_door_open?
      out[:status_icons] << "washing-machine" if home_assistant_api.washer_needs_attention?
      out[:status_icons] << "dryer-heat" if home_assistant_api.dryer_needs_attention?
      out[:status_icons] << "car-side-bolt" if home_assistant_api.car_needs_plugged_in?
      out[:status_icons] << "video" if home_assistant_api.active_video_call?

      home_assistant_api.unavailable_door_sensors.each do |door_sensor_name|
        out[:status_icons_with_labels] << ["triangle-exclamation", door_sensor_name]
      end

      home_assistant_api.unlocked_doors.each do |door_name|
        out[:status_icons_with_labels] << ["lock-open", door_name]
      end

      home_assistant_api.open_doors.each do |door_name|
        out[:status_icons_with_labels] << ["door-open", door_name]
      end

      home_assistant_api.roborock_errors.each do |error|
        out[:status_icons_with_labels] << ["vacuum-robot", error]
      end

      home_assistant_api.low_batteries.each do |low_battery|
        out[:status_icons_with_labels] << ["battery-slash", low_battery]
      end
    else
      out[:status_icons_with_labels] << ["triangle-exclamation", "Home Assistant"]
    end

    if google_calendar_api.healthy?
      raw_events << google_calendar_api.data
    else
      out[:status_icons_with_labels] << ["triangle-exclamation", "Google Calendar"]
    end

    if sonos_api.healthy?
      out[:sonos_status] = sonos_api.status
    else
      out[:status_icons] << ["triangle-exclamation", "Sonos"]
    end

    if home_assistant_api.online?
      if birdnet_api.healthy?
        out[:birdnet_most_unusual_species_trailing_24h] = birdnet_api.most_unusual_species_trailing_24h
      else
        out[:status_icons_with_labels] << ["triangle-exclamation", "Birdnet"]
      end
    end

    if home_assistant_api.online?
      if weather_kit_api.healthy?
        raw_events << (
          weather_kit_api.daily_calendar_events +
          weather_kit_api.hourly_calendar_events +
          weather_kit_api.precip_calendar_events +
          weather_kit_api.weather_alert_calendar_events
        )

        condition = weather_kit_api.data.dig(:forecastNextHour, :summary)&.first.to_h[:condition]

        if condition != "clear"
          minutely_weather_minutes_icon = (condition == "snow") ? "snowflake" : "raindrops"
          minutely_weather_minutes = weather_kit_api.data.dig(:forecastNextHour, :minutes)&.first(60)

          out[:minutely_weather_minutes] = minutely_weather_minutes
          out[:minutely_weather_minutes_icon] = minutely_weather_minutes_icon
        end
      else
        out[:status_icons_with_labels] << ["triangle-exclamation", "Apple Weather"]
      end
    end
    # :nocov:

    out[:day_groups] =
      (0...5).each_with_object([]).map do |day_index|
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

        {
          day_name: day_name,
          show_daily_events: day_index.zero? ? date.hour <= 19 : true,
          events: calendar_feed.events_for(
            (day_index.zero? ? current_time : date.beginning_of_day).utc,
            date.end_of_day.utc,
            raw_events.flatten
          )
        }
      end

    out
  end
end

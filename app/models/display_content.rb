class DisplayContent
  def call
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    weather_kit_api = WeatherKitApi.new
    google_calendar_api = GoogleCalendarApi.new
    calendar_feed = CalendarFeed.new

    events = 
      weather_kit_api.daily_calendar_events +
      [calendar_feed.baby_age_event] +
      weather_kit_api.hourly_calendar_events +
      weather_kit_api.precip_calendar_events +
      weather_kit_api.weather_alert_calendar_events +
      google_calendar_api.data

    day_groups =
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
            events
          )
        }
      end

    # :nocov:
    status_icons = []
    status_icons_with_labels = []

    home_assistant_api = HomeAssistantApi.new

    if home_assistant_api.healthy?
      status_icons << "box-open" if home_assistant_api.package_present?
      status_icons << "garage-open" if home_assistant_api.garage_door_open?
      status_icons << "washing-machine" if home_assistant_api.washer_needs_attention?
      status_icons << "dryer-heat" if home_assistant_api.dryer_needs_attention?
      status_icons << "car-side-bolt" if home_assistant_api.car_needs_plugged_in?
      status_icons << "video" if home_assistant_api.active_video_call?

      home_assistant_api.unavailable_door_sensors.each do |door_sensor_name|
        status_icons_with_labels << ["triangle-exclamation", door_sensor_name]
      end
  
      home_assistant_api.unlocked_doors.each do |door_name|
        status_icons_with_labels << ["lock-open", door_name]
      end
  
      home_assistant_api.open_doors.each do |door_name|
        status_icons_with_labels << ["door-open", door_name]
      end

      home_assistant_api.roborock_errors.each do |error|
        status_icons_with_labels << ["vacuum-robot", error]
      end

      home_assistant_api.low_batteries.each do |low_battery|
        status_icons_with_labels << ["battery-slash", low_battery]
      end
    else
      status_icons << "house-circle-exclamation"
    end

    status_icons << "calendar-circle-exclamation" if !google_calendar_api.healthy?
    status_icons << "cloud-slash" if !weather_kit_api.healthy?

    sonos_api = SonosApi.new
    status_icons << "volume-slash" if !sonos_api.healthy?

    birdnet_api = BirdnetApi.new
    status_icons << "microphone-slash" if !birdnet_api.healthy?
    

    minutely_weather_minutes = []
    minutely_weather_minutes_icon = nil
    condition = weather_kit_api.data.dig("forecastNextHour", "summary")&.first.to_h["condition"]

    if (weather_kit_api.healthy? && condition != "clear")
      minutely_weather_minutes_icon = condition == "snow" ? "snowflake" : "raindrops"
      minutely_weather_minutes = weather_kit_api.data["forecastNextHour"]["minutes"].first(60)
    end
    # :nocov:

    {
      birdnet_most_unusual_species_trailing_24h: birdnet_api.most_unusual_species_trailing_24h,
      minutely_weather_minutes: minutely_weather_minutes,
      minutely_weather_minutes_icon: minutely_weather_minutes_icon,
      status_icons: status_icons,
      status_icons_with_labels: status_icons_with_labels,
      current_temperature: home_assistant_api.feels_like_temperature,
      day_groups: day_groups,
      sonos_status: sonos_api.status,
      timestamp: current_time.strftime("%-l:%M %p")
    }
  end
end
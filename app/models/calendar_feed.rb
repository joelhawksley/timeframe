class CalendarFeed
  def self.baby_age_event(birthdate = Date.parse(Timeframe::Application.config.local["birthdate"]))
    day_count = Date.today - birthdate
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

    if week_count > 24
      time_difference = TimeDifference.between(birthdate, Date.today).in_general
      months = time_difference[:months]
      weeks = time_difference[:weeks]
      days = time_difference[:days]

      summary = ""
      summary << "#{months}m" if months > 0
      summary << "#{weeks}w" if weeks > 0
      summary << "#{days}d" if days > 0
    else
      summary =
        if remainder > 0
          if week_count > 0
            "#{week_count}w#{remainder}d"
          else
            "#{remainder}d"
          end
        else
          "#{week_count}w"
        end
    end

    CalendarEvent.new(
      id: "_baby_age",
      starts_at: Date.today.to_time,
      ends_at: (Date.today + 1.day).to_time,
      icon: "baby-carriage",
      summary: summary
    )
  end

  def self.calendar_events
    Current.calendar_events ||= GoogleAccount.all.map(&:events).flatten
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def self.events_for(starts_at, ends_at)
    filtered_events = (
      WeatherKitApi.daily_calendar_events +
      [baby_age_event] +
      WeatherKitApi.hourly_calendar_events +
      WeatherKitApi.precip_calendar_events +
      WeatherKitApi.weather_alert_calendar_events +
      calendar_events
    )

    filtered_events = filtered_events.compact.select do |event|
      if event.start_i == event.end_i
        [event.start_i, event.end_i].any? { (starts_at.to_i...ends_at.to_i).cover?(_1) }
      else
        (event.start_i...event.end_i).overlaps?(starts_at.to_i...ends_at.to_i)
      end
    end

    # Merge duplicate events, merging the letter with a custom rule if so
    filtered_events = filtered_events.group_by { _1.id }
      .map do |_k, v|
        if v.length > 1
          letters = v.map { |iv| iv.letter }
          letter =
            if letters.uniq.length == 1
              letters[0]
            elsif letters.include?("+")
              "+"
            else
              letters[0]
            end

          out = v[0]
          out.letter = letter
          out
        else
          v[0]
        end
      end

    {
      daily: filtered_events.select(&:daily?),
      periodic: filtered_events
        .reject(&:daily?)
        .sort_by(&:start_i)
    }
  end
end

class CalendarFeed
  def baby_age_event(date, icon = "baby-carriage")
    date = Date.parse(date) if date.is_a?(String)
    today = Time.now.in_time_zone(Timeframe::Application.config.local["timezone"]).to_date

    day_count = if date > today
      date - 1.day - today
    else
      today - 1.day - date
    end

    week_count = (day_count / 7).to_i

    if week_count > 104
      time_difference = TimeDifference.between(date, today).in_general
      months = time_difference[:months]
      weeks = time_difference[:weeks]
      days = time_difference[:days]
      years = time_difference[:years]

      summary = ""
      summary << "#{years}y" if years > 0
      summary << "#{months}m" if months > 0

      if date.day != today.day
        summary << "#{weeks}w" if weeks > 0
        summary << "#{days}d" if days > 0
      end
    elsif week_count > 24
      time_difference = TimeDifference.between(date, today).in_general
      months = time_difference[:months] + (time_difference[:years] * 12)
      weeks = time_difference[:weeks]
      days = time_difference[:days]

      summary = ""
      summary << "#{months}m" if months > 0

      if date.day != today.day
        summary << "#{weeks}w" if weeks > 0
        summary << "#{days}d" if days > 0
      end
    else
      remainder = (day_count % 7).to_i

      summary =
        if remainder > 0
          if week_count > 0
            "#{week_count}w#{remainder}d"
          else
            # :nocov:
            "#{remainder}d"
            # :nocov:
          end
        else
          "#{week_count}w"
        end
    end

    CalendarEvent.new(
      id: "_baby_age_#{date}",
      starts_at: Date.today.to_time,
      ends_at: (Date.today + 1.day).to_time,
      icon: icon,
      summary: summary
    )
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def events_for(starts_at, ends_at, events = [], private_mode = false)
    filtered_events = events.compact.select do |event|
      if event.start_i == event.end_i
        [event.start_i, event.end_i].any? { (starts_at.to_i...ends_at.to_i).cover?(_1) }
      else
        (event.start_i...event.end_i).overlaps?(starts_at.to_i...ends_at.to_i)
      end
    end.select { !_1.omit? }

    # Merge duplicate events, merging the icon with a custom rule if so
    filtered_events = filtered_events.group_by { _1.id }
      .map do |_k, v|
        if v.length > 1
          icons = v.map { |iv| iv.icon }
          icon =
            if icons.uniq.length == 1
              icons[0]
            elsif icons.include?("+")
              "+"
            else
              icons[0]
            end

          out = v[0]
          out.icon = icon
          out
        else
          v[0]
        end
      end

    filtered_events = filtered_events.select { !_1.private? } if private_mode

    {
      daily: filtered_events.select(&:daily?),
      periodic: filtered_events
        .reject(&:daily?)
        .sort_by(&:start_i)
    }
  end
end

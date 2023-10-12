# frozen_string_literal: true

class CalendarFeed
  def self.baby_age_event(birthdate = Date.parse(Timeframe::Application.config.local["birthdate"]))
    day_count = Date.today - birthdate
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

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
      WeatherKitAccount.daily_calendar_events +
      [baby_age_event] +
      WeatherKitAccount.hourly_calendar_events +
      WeatherKitAccount.precip_calendar_events +
      [WeatherAlert.calendar_event] +
      calendar_events
    )

    filtered_events = filtered_events.compact.map(&:to_h).map(&:with_indifferent_access).select do |event|
      (event[:start_i]...event[:end_i]).overlaps?(starts_at.to_i...ends_at.to_i)
    end

    filtered_events = filtered_events.group_by { _1[:id] } # Merge duplicate events, merging the letter with a custom rule if so
      .map do |_k, v|
        if v.length > 1
          letters = v.map { |iv| iv[:letter] }
          letter =
            if letters.uniq.length == 1
              letters[0]
            elsif letters.include?('+')
              '+'
            else
              letters[0]
            end

          out = v[0]
          out[:letter] = letter
          out
        else
          v[0]
        end
      end

    {
      daily: filtered_events.select { |event| event['daily'] },
      periodic: filtered_events.
        reject { |event| event['daily'] }.
        sort_by { |event| event['start_i'] }
    }
  end
end
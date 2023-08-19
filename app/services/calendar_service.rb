# frozen_string_literal: true

class CalendarService
  def self.baby_age_string(birthdate = Date.parse(Timeframe::Application.config.local["birthdate"]))
    day_count = Date.today - birthdate
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

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

  def self.calendar_events
    Value.find_or_create_by(key: "calendar_events").value.values.map(&:values).flatten.map(&:values).flatten
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def self.events_for(starts_at, ends_at)
    filtered_events = (
      WeatherKitService.calendar_events +
      WeatherKitService.precip_calendar_events +
      [WeatherAlertService.weather_alert_calendar_event] +
      calendar_events
    ).compact.select do |event|
      (event['start_i']...event['end_i']).overlaps?(starts_at.to_i...ends_at.to_i)
    end.group_by { _1['id'] } # Merge duplicate events, merging the letter with a custom rule if so
      .map do |_k, v|
        if v.length > 1
          letters = v.map { |iv| iv['letter'] }
          letter =
            if letters.uniq.length == 1
              letters[0]
            elsif letters.include?('+')
              '+'
            else
              letters[0]
            end

          out = v[0]
          out['letter'] = letter
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
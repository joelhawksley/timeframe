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
    Value.find_or_create_by(key: "calendar_events").value
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def self.events_for(beginning_i, ending_i)
    filtered_events = (
      WeatherKitService.calendar_events +
      WeatherKitService.precip_calendar_events +
      [WeatherAlertService.weather_alert_calendar_event] +
      calendar_events.values.flatten.map(&:values).flatten
    ).compact.select do |event|
      (event['start_i']..event['end_i']).overlaps?(beginning_i...ending_i)
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
      all_day: filtered_events.select { |event| event['all_day'] },
      periodic: filtered_events.
        reject { |event| event['all_day'] }.
        sort_by { |event| event['start_i'] }
    }
  end
end
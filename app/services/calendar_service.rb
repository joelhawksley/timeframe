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

  def self.sorted_calendar_events_array
    @sorted_calendar_events_array ||= Value.sorted_calendar_events_array
  end

  # Returns calendar events for a given UTC integer time range,
  # adding a `time` key for the time formatted for the user's timezone
  def self.events_for(beginning_i, ending_i)
    filtered_events = (
      HourlyWeatherService.calendar_events +
      HourlyWeatherService.precip_calendar_events +
      [WeatherAlertService.weather_alert_calendar_event] +
      sorted_calendar_events_array
    ).compact.select do |event|
      (event['start_i']..event['end_i']).overlaps?(beginning_i...ending_i)
    end

    # Merge duplicate events, merging the letter with a custom rule if so
    filtered_events
      .group_by { _1['id'] }
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

    all_day_events = filtered_events.select { |event| event['all_day'] }

    mappings = [
      "Birthdays",
      "Us",
      "Caitlin",
      "Caitlin Exercise Log",
      "Captain",
      "Dinner",
      "Friends & Family",
      "HelloFresh",
      "Holidays in United States",
      "Home",
      "Joel",
      "Joel Health",
      "On Call Schedule for joelhawksley",
      "joelhawksley@github.com",
      "Work",
    ]

    groupings = all_day_events.group_by { |event| event['calendar'] }

    groupings.transform_values! do |arr|
      arr.sort! do |x, y|
        # if this result is 1 means x should come later relative to y
        # if this result is -1 means x should come earlier relative to y
        # if this result is 0 means both are same so position doesn't matter
        if x['calendar'] != 'Dinner'
          if !x['multi_day'] && y['multi_day']
            -1
          elsif x['multi_day'] && !y['multi_day']
            1
          else
            0
          end
        else
          0
        end
      end
    end

    pairs = groupings.flat_map do |calendar, events|
      events.map do |event|
        [calendar, event]
      end
    end

    pairs.sort_by! do |pair|
      mappings.index(pair[0])
    end.map!(&:last)

    {
      all_day: pairs,
      periodic: filtered_events.
        reject { |event| event['all_day'] }.
        sort_by { |event| event['start_i'] }
    }
  end
end
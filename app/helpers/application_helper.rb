# frozen_string_literal: true

module ApplicationHelper
  def render_json_payload
    day_groups =
      (0...5).each_with_object([]) do |day_index, memo|
        date = Time.now.in_time_zone(Timeframe::Application.config.local["timezone"]) + day_index.day

        start_i =
          case day_index
          when 0
            # Add 180 seconds so that events ending at the top of the hour are not shown for the following half hour
            Time.now.in_time_zone(Timeframe::Application.config.local["timezone"]).utc.to_i + 180
          else
            date.beginning_of_day.utc.to_i
          end

        events = CalendarService.events_for(start_i, date.end_of_day.utc.to_i)
        all_day_events = events.select { |event| event['all_day'] }

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

        all_day_events.sort! do |x, y|
          # if this result is 1 means x should come later relative to y
          # if this result is -1 means x should come earlier relative to y
          # if this result is 0 means both are same so position doesn't matter
          if !x['multi_day'] && y['multi_day']
            -1
          elsif x['multi_day'] && !y['multi_day']
            1
          else
            0
          end
        end

        out = {
          day_index: day_index,
          day_name: date.strftime('%A'),
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: {
            all_day: pairs,
            periodic: events.reject { |event| event['all_day'] }
          }
        }

        high = Value.weather['wunderground_forecast']['calendarDayTemperatureMax'][day_index]
        low = Value.weather['wunderground_forecast']['calendarDayTemperatureMin'][day_index]

        out[:precip_label] = if Value.weather['wunderground_forecast']['qpfSnow'][day_index] > 0
                               " <i class='fa-regular fa-snowflake'></i> #{Value.weather['wunderground_forecast']['qpfSnow'][day_index].round}\""
                             else
                               " #{Value.weather['wunderground_forecast']['qpf'][day_index].round}%"
                             end
        out[:temperature_range] = "&#8593;#{high} &#8595;#{low}".html_safe
        out[:precip_probability] = Value.weather['wunderground_forecast']['qpf'][day_index]

        memo << out
      end

    current_time = DateTime.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])
    
    current_nws_hour =
      Value.weather['nws_hourly']
      .find do
        (_1['start_i'].._1['end_i'])
      .cover?(current_time.to_i)
      end
    
    out =
      {
        current_temperature: "#{current_nws_hour['temperature']}°",
        day_groups: day_groups,
        timestamp: current_time.strftime('%-l:%M %p')
      }

    out
  end
end

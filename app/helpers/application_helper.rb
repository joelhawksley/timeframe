# frozen_string_literal: true

module ApplicationHelper
  def render_json_payload
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    day_groups =
      (0...5).each_with_object([]) do |day_index, memo|
        date = current_time + day_index.day

        start_i =
          case day_index
          when 0
            current_time.utc.to_i
          else
            date.beginning_of_day.utc.to_i
          end

        out = {
          day_index: day_index,
          day_name: date.strftime('%A'),
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: CalendarService.events_for(start_i, date.end_of_day.utc.to_i),
          temperature_range: PirateWeatherService.temperature_range_for(date.to_date)
        }

        memo << out
      end

    out =
      {
        current_temperature: "#{PirateWeatherService.current_temperature.to_i}°",
        day_groups: day_groups,
        timestamp: current_time.strftime('%-l:%M %p')
      }

    out
  end
end

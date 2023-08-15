# frozen_string_literal: true

module ApplicationHelper
  def render_json_payload
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    day_groups =
      (0...5).each_with_object([]) do |day_index, memo|
        date = current_time + day_index.day

        starts_at =
          case day_index
          when 0
            current_time.utc
          else
            date.beginning_of_day.utc
          end

        out = {
          day_index: day_index,
          day_name: date.strftime('%A'),
          show_all_day_events: day_index.zero? ? date.hour <= 19 : true,
          events: CalendarService.events_for(starts_at, date.end_of_day.utc),
          temperature_range: WeatherKitService.temperature_range_for(date.to_date)
        }

        memo << out
      end

    out =
      {
        current_temperature: "#{WeatherKitService.current_temperature}°",
        day_groups: day_groups,
        timestamp: current_time.strftime('%-l:%M %p')
      }

    out
  end
end

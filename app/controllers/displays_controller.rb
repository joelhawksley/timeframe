class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: view_object}
  end

  def mira
    @refresh = true

    render "mira", locals: {view_object: view_object}
  end

  private

  def view_object
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    day_groups =
      (0...5).each_with_object([]).map do |day_index|
        date = current_time + day_index.day

        {
          day_name: date.strftime('%A'),
          show_daily_events: day_index.zero? ? date.hour <= 19 : true,
          events: CalendarService.events_for(
            (day_index.zero? ? current_time : date.beginning_of_day).utc,
            date.end_of_day.utc
          ),
          temperature_range: WeatherKitService.temperature_range_for(date.to_date)
        }
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
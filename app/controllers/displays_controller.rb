class DisplaysController < ApplicationController
  layout "display"

  def thirteen
    render "thirteen", locals: {view_object: view_object}
  end

  def mira
    @refresh = true

    # :nocov:
    begin
      render "mira", locals: {view_object: view_object}
    rescue => e
      Log.create(
        globalid: "Timeframe.display",
        event: "render error",
        message: e.message + e.backtrace.join("\n")
      )

      render "error", locals: {klass: e.class.to_s, message: e.message}
      
    end
    # :nocov:
  end

  private

  def view_object
    current_time = Time.now.utc.in_time_zone(Timeframe::Application.config.local["timezone"])

    day_groups =
      (0...5).each_with_object([]).map do |day_index|
        date = current_time + day_index.day

        day_name =
          case day_index
          when 0
            "Today"
          when 1
            "Tomorrow"
          else
            date.strftime("%A")
          end

        {
          day_name: day_name,
          show_daily_events: day_index.zero? ? date.hour <= 19 : true,
          events: CalendarFeed.events_for(
            (day_index.zero? ? current_time : date.beginning_of_day).utc,
            date.end_of_day.utc
          )
        }
      end

    {
      current_temperature: HomeAssistantApi.feels_like_temperature,
      day_groups: day_groups,
      timestamp: current_time.strftime("%-l:%M %p")
    }
  end
end

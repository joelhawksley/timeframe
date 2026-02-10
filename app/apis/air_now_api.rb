class AirNowApi < Api
  def daily_calendar_events
    return {} unless healthy?

    data.group_by { it[:ParameterName] }.flat_map do |parameter_name, days|
      days.flat_map do |day|
        next if day[:Category][:Number] <= 2

        CalendarEvent.new(
          id: "_air_now_#{day[:DateForecast]}_#{parameter_name}",
          starts_at: Date.parse(day[:DateForecast]).in_time_zone(Timeframe::Application.config.local["timezone"]),
          ends_at: Date.parse(day[:DateForecast]).in_time_zone(Timeframe::Application.config.local["timezone"]) + 1.day,
          icon: "triangle-exclamation",
          summary: "#{parameter_name} #{day[:Category][:Name]}"
        )
      end.compact
    end
  end

  def time_before_unhealthy
    30.minutes
  end
end

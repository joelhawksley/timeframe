# frozen_string_literal: true

class DemoDeviceContent
  def call(timezone: "UTC", current_time: nil, days: 5, include_precip: true, include_wind: true)
    current_time ||= Time.now.utc.in_time_zone(timezone)

    out = {}
    out[:current_temperature] = "72°"
    out[:timestamp] = current_time.strftime("%-l:%M %p")
    out[:current_time] = current_time

    out[:top_left] = [
      {icon: "door-open", label: "Front Door"}
    ]

    out[:top_right] = [
      {icon: "bird", label: "Spotted Towhee"}
    ]

    out[:weather_status] = [
      {icon: "arrow-up", label: "12", rotation: 45}
    ]

    out[:now_playing] = {artist: "Tycho", track: "A Walk"}

    out[:minutely_weather_minutes] = (0...60).map do |i|
      chance = if i < 10
        0.1
      elsif i < 30
        0.3 + (i - 10) * 0.035
      elsif i < 45
        1.0 - (i - 30) * 0.05
      else
        0.2
      end

      intensity = if i < 10
        0.0
      elsif i < 30
        0.5 + (i - 10) * 0.1
      elsif i < 45
        2.5 - (i - 30) * 0.15
      else
        0.2
      end

      {precipitationChance: chance.clamp(0.0, 1.0), precipitationIntensity: intensity.clamp(0.0, 3.0)}
    end
    out[:minutely_weather_minutes_icon] = "weather-rainy"

    out[:minutely_precipitation_bars] = out[:minutely_weather_minutes].map do |minute|
      (minute[:precipitationChance] * minute[:precipitationIntensity] * 50).clamp(3, 100).round
    end

    out[:attribution] = nil
    out[:private_mode] = false

    out[:day_groups] = build_day_groups(current_time, timezone, days: days, include_wind: include_wind)

    out
  end

  private

  def build_day_groups(current_time, timezone, days: 5, include_wind: true)
    today = current_time.to_date
    vacation = DeviceEvent.new(
      starts_at: (today - 2.days).beginning_of_day,
      ends_at: (today + 5.days).beginning_of_day,
      summary: "Vacation",
      icon: "plus",
      daily: true,
      timezone: timezone
    )

    (0...days).map do |day_index|
      date = current_time + day_index.days

      day_name = case day_index
      when 0 then "Today"
      when 1 then "Tomorrow"
      else date.strftime("%A")
      end

      show_daily = (day_index.zero? && current_time.hour < 20) || !day_index.zero?
      events = events_for_day(day_index, date, current_time, vacation, timezone, include_wind: include_wind)

      {
        day_name: day_name,
        date: date.to_date,
        show_daily: show_daily,
        daily: events[:daily].map { |e| e.as_json(date: date.to_date) },
        periodic: events[:periodic].map { |e| e.as_json(date: date.to_date) }
      }
    end
  end

  def events_for_day(day_index, date, current_time, vacation, timezone, include_wind: true)
    daily = []
    periodic = []

    case day_index
    when 0
      daily << DeviceEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: (date + 1.day).beginning_of_day,
        summary: "Sarah Johnson",
        description: "1990",
        icon: "cake-variant",
        daily: true,
        timezone: timezone
      )

      daily << vacation

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 9),
        summary: "Morning standup with the entire engineering team and product managers",
        icon: "alpha-j",
        location: "Conference Room A",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 9),
        ends_at: date.change(hour: 9, min: 30),
        summary: "1:1 with Alex",
        icon: "alpha-j",
        location: "Zoom",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "68°",
        icon: "weather-partly-cloudy",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 16),
        summary: "74°",
        icon: "weather-sunny",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 17),
        ends_at: date.change(hour: 18),
        summary: "Soccer practice",
        icon: "alpha-f",
        location: "Greenfield Park",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "64°",
        icon: "weather-night",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 21),
        ends_at: (date + 1.day).change(hour: 1),
        summary: "Movie night",
        icon: "alpha-f",
        timezone: timezone
      )

    when 1
      daily << vacation

      daily << DeviceEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: (date + 1.day).beginning_of_day,
        summary: "Recycling",
        icon: "home",
        location: "Put out by 7am",
        daily: true,
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "55°",
        icon: "weather-sunny",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 10),
        ends_at: date.change(hour: 11),
        summary: "Dentist",
        icon: "alpha-s",
        location: "123 Main St",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "70°",
        icon: "weather-partly-cloudy",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 14),
        ends_at: date.change(hour: 15, min: 30),
        summary: "Piano lesson",
        icon: "alpha-s",
        location: "Music Academy",
        timezone: timezone
      )

      if include_wind
        periodic << DeviceEvent.new(
          starts_at: date.change(hour: 15),
          ends_at: date.change(hour: 19),
          summary: "Gusts up to 25mph",
          icon: "arrow-up",
          icon_rotation: 225,
          timezone: timezone
        )
      end

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "48°",
        icon: "weather-night",
        timezone: timezone
      )

    when 2
      daily << vacation

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "62°",
        icon: "weather-cloudy",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 9),
        ends_at: date.change(hour: 10, min: 30),
        summary: "Team retro",
        icon: "alpha-j",
        location: "Conference Room B",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "67°",
        icon: "weather-rainy",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 13),
        ends_at: date.change(hour: 14),
        summary: "Lunch with Maria",
        icon: "alpha-j",
        location: "Cafe Luna",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 13, min: 30),
        ends_at: date.change(hour: 14, min: 30),
        summary: "Call with client",
        icon: "alpha-j",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "55°",
        icon: "weather-night",
        timezone: timezone
      )

    when 3
      daily << vacation

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "58°",
        icon: "weather-sunny",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "75°",
        icon: "weather-sunny",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 17, min: 30),
        summary: "Swimming",
        icon: "alpha-f",
        location: "Community Pool",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "62°",
        icon: "weather-night-partly-cloudy",
        timezone: timezone
      )

    when 4
      daily << vacation

      daily << DeviceEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: (date + 1.day).beginning_of_day,
        summary: "Trash day",
        icon: "home",
        daily: true,
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "60°",
        icon: "weather-partly-cloudy",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "72°",
        icon: "weather-sunny",
        timezone: timezone
      )

      periodic << DeviceEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "58°",
        icon: "weather-night",
        timezone: timezone
      )
    end

    CalendarFeed.new.events_for(
      (day_index.zero? ? current_time : date.beginning_of_day).utc,
      date.end_of_day.utc,
      daily + periodic,
      false
    )
  end
end

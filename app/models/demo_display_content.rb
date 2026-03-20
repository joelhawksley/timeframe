# frozen_string_literal: true

class DemoDisplayContent
  def call
    tz = HomeAssistantApi.new.time_zone || "UTC"
    current_time = Time.now.utc.in_time_zone(tz)

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

    out[:attribution] = nil

    out[:day_groups] = build_day_groups(current_time)

    out
  end

  private

  def build_day_groups(current_time)
    today = current_time.to_date
    vacation = CalendarEvent.new(
      starts_at: (today - 2.days).beginning_of_day,
      ends_at: (today + 5.days).beginning_of_day,
      summary: "Vacation",
      icon: "plus",
      daily: true
    )

    (0...5).map do |day_index|
      date = current_time + day_index.days

      day_name = case day_index
      when 0 then "Today"
      when 1 then "Tomorrow"
      else date.strftime("%A")
      end

      {
        day_name: day_name,
        date: date.to_date,
        events: events_for_day(day_index, date, current_time, vacation),
        is_today: day_index.zero?
      }
    end
  end

  def events_for_day(day_index, date, current_time, vacation)
    daily = []
    periodic = []

    case day_index
    when 0 # Today
      daily << CalendarEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: date.end_of_day,
        summary: "Sarah Johnson",
        description: "1990",
        icon: "cake-variant",
        daily: true
      )

      daily << vacation

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 9),
        summary: "Morning standup with the entire engineering team and product managers",
        icon: "alpha-j",
        location: "Conference Room A"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 9),
        ends_at: date.change(hour: 9, min: 30),
        summary: "1:1 with Alex",
        icon: "alpha-j",
        location: "Zoom"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "68°",
        icon: "weather-partly-cloudy"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 16),
        summary: "74°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 17),
        ends_at: date.change(hour: 18),
        summary: "Soccer practice",
        icon: "alpha-f",
        location: "Greenfield Park"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "64°",
        icon: "weather-night"
      )

      # Event spanning past midnight (edge case)
      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 21),
        ends_at: (date + 1.day).change(hour: 1),
        summary: "Movie night",
        icon: "alpha-f"
      )

    when 1 # Tomorrow
      daily << vacation

      daily << CalendarEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: (date + 1.day).beginning_of_day,
        summary: "Recycling",
        icon: "home",
        location: "Put out by 7am",
        daily: true
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "55°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 10),
        ends_at: date.change(hour: 11),
        summary: "Dentist",
        icon: "alpha-s",
        location: "123 Main St"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "70°",
        icon: "weather-partly-cloudy"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 14),
        ends_at: date.change(hour: 15, min: 30),
        summary: "Piano lesson",
        icon: "alpha-s",
        location: "Music Academy"
      )

      # Wind gust event with rotated arrow (edge case)
      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 15),
        ends_at: date.change(hour: 19),
        summary: "Gusts up to 25mph",
        icon: "arrow-up",
        icon_rotation: 225
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 16),
        summary: "65°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "58°",
        icon: "weather-night"
      )

    when 2
      daily << vacation

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "60°",
        icon: "cloud"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 9),
        ends_at: date.change(hour: 10),
        summary: "Team retrospective",
        icon: "alpha-j",
        location: "Board Room"
      )

      # Precipitation event
      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 11),
        ends_at: date.change(hour: 15),
        summary: "Rain (0.3\")",
        icon: "weather-rainy"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "58°",
        icon: "weather-rainy"
      )

      # Overlapping event (edge case)
      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 13),
        ends_at: date.change(hour: 14),
        summary: "Lunch with Pat",
        icon: "alpha-f"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 13, min: 30),
        ends_at: date.change(hour: 14, min: 30),
        summary: "Call with client",
        icon: "alpha-j"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 16),
        summary: "55°",
        icon: "cloud"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "50°",
        icon: "weather-night"
      )

    when 3
      daily << vacation

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "52°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 9),
        ends_at: date.change(hour: 9, min: 45),
        summary: "Yoga",
        icon: "alpha-s"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "71°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 15),
        ends_at: date.change(hour: 16),
        summary: "Grocery run",
        icon: "alpha-f",
        location: "Whole Foods"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 18),
        ends_at: date.change(hour: 19, min: 30),
        summary: "Dinner party",
        icon: "alpha-f",
        location: "The Smiths"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "60°",
        icon: "weather-night"
      )

    when 4
      daily << vacation

      daily << CalendarEvent.new(
        starts_at: date.beginning_of_day,
        ends_at: (date + 1.day).beginning_of_day,
        summary: "Library books due",
        icon: "alpha-f",
        daily: true
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 8),
        ends_at: date.change(hour: 8),
        summary: "48°",
        icon: "weather-sunny"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 10),
        ends_at: date.change(hour: 11, min: 30),
        summary: "Hike",
        icon: "alpha-f",
        location: "Mt. Tabor"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 12),
        ends_at: date.change(hour: 12),
        summary: "66°",
        icon: "weather-partly-cloudy"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 16),
        ends_at: date.change(hour: 16),
        summary: "62°",
        icon: "weather-partly-cloudy"
      )

      periodic << CalendarEvent.new(
        starts_at: date.change(hour: 20),
        ends_at: date.change(hour: 20),
        summary: "54°",
        icon: "weather-night"
      )
    end

    if day_index.zero?
      periodic.reject! { |event| event.ends_at < current_time }
    end

    {daily: daily, periodic: periodic}
  end
end

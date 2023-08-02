class CalendarEvent
  DAY_IN_SECONDS = 86_400

  def initialize(
    start_i:, 
    end_i:, 
    calendar:,
    summary:,
    icon: nil,
    letter: nil,
    location: nil,
    all_day: false,
    id: SecureRandom.hex
  )
    @id, @start_i, @end_i, @calendar, @icon, @letter, @summary, @location, @all_day = 
      id, start_i, end_i, calendar, icon, letter, summary, location, all_day
  end

  def to_h
    {
      id: @id,
      start_i: @start_i,
      end_i: @end_i,
      calendar: @calendar,
      icon: @icon,
      letter: @letter,
      summary: @summary,
      location: @location,
      multi_day: ((@end_i - @start_i) > DAY_IN_SECONDS),
      all_day: @all_day,
      time: EventTimeService.call(@start_i, @end_i)
    }
  end
end
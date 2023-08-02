class CalendarEvent
  def initialize(
    start_i:, 
    end_i:, 
    calendar:,
    summary:,
    icon: nil,
    letter: nil,
    location: nil,
    multi_day: false,
    all_day: false,
    id: SecureRandom.hex
  )
    @id, @start_i, @end_i, @calendar, @icon, @letter, @summary, @location, @multi_day, @all_day = 
      id, start_i, end_i, calendar, icon, letter, summary, location, multi_day, all_day
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
      multi_day: @multi_day,
      all_day: @all_day,
      time: EventTimeService.call(@start_i, @end_i)
    }
  end
end
class CalendarEvent
  DAY_IN_SECONDS = 86_400

  def initialize(
    start_i:,
    end_i:,
    summary:,
    description: nil,
    icon: nil,
    letter: nil,
    location: nil,
    all_day: false,
    id: SecureRandom.hex
  )
    @id, @start_i, @end_i, @icon, @letter, @summary, @description, @location, @all_day =
      id, start_i, end_i, icon, letter, summary, description, location, all_day
  end

  def to_h
    {
      id: @id,
      start_i: @start_i,
      end_i: @end_i,
      icon: @icon,
      letter: @letter,
      summary: summary,
      location: @location,
      multi_day: ((@end_i - @start_i) > DAY_IN_SECONDS),
      all_day: @all_day,
      time: EventTimeService.call(@start_i, @end_i)
    }
  end

  def [](index)
    to_h[index.to_sym]
  end

  def []=(index, value)
    instance_variable_set(:"@#{index}", value)
  end

  private

  def summary
    if (1900..2100).cover?(@description.to_s.to_i)
      counter = Date.today.year - @description.to_s.to_i

      "#{@summary} (#{counter})"
    else
      @summary
    end
  end
end
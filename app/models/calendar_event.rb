class CalendarEvent
  DAY_IN_SECONDS = 86_400

  def initialize(
    starts_at:,
    ends_at:,
    summary:,
    description: nil,
    icon: nil,
    letter: nil,
    location: nil,
    daily: false,
    id: SecureRandom.hex
  )
    @id, @icon, @letter, @summary, @description, @location, @daily =
      id, icon, letter, summary, description, location, daily

    case starts_at
    when Integer
      @starts_at = Time.at(starts_at).in_time_zone(Timeframe::Application.config.local["timezone"])
    else
      @starts_at = starts_at
    end

    case ends_at
    when Integer
      @ends_at = Time.at(ends_at).in_time_zone(Timeframe::Application.config.local["timezone"])
    else
      @ends_at = ends_at
    end
  end

  def to_h
    {
      id: @id,
      starts_at: @starts_at,
      ends_at: @ends_at,
      start_i: start_i,
      end_i: end_i,
      icon: @icon,
      letter: @letter,
      summary: summary,
      location: @location,
      multi_day: ((end_i - start_i) > DAY_IN_SECONDS),
      daily: @daily,
      time: EventTimeService.call(start_i, end_i),
      daily: daily
    }
  end

  def daily
    length_in_seconds = end_i - start_i

    return false if length_in_seconds == 0

    length_in_seconds % DAY_IN_SECONDS == 0
  end

  def start_i
    @starts_at.to_i
  end

  def end_i
    @ends_at.to_i
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
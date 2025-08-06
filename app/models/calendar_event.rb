class CalendarEvent
  DAY_IN_SECONDS = 86_400

  attr_reader :id, :starts_at, :ends_at, :multi_day, :location
  attr_accessor :icon

  def self.for_duration(
    date:,
    today: Time.now.in_time_zone(Timeframe::Application.config.local["timezone"]).to_date,
    icon: nil
  )
    date = Date.parse(date) if date.is_a?(String)

    day_count = if date > today
      date - 1.day - today
    else
      today - 1.day - date
    end

    week_count = (day_count / 7).to_i

    if week_count > 104
      time_difference = TimeDifference.between(date, today).in_general
      months = time_difference[:months]
      weeks = time_difference[:weeks]
      days = time_difference[:days]
      years = time_difference[:years]

      summary = +""
      summary << "#{years}y" if years > 0
      summary << "#{months}m" if months > 0

      if date.day != today.day
        summary << "#{weeks}w" if weeks > 0
        summary << "#{days}d" if days > 0
      end
    elsif week_count > 24
      time_difference = TimeDifference.between(date, today).in_general
      months = time_difference[:months] + (time_difference[:years] * 12)
      weeks = time_difference[:weeks]
      days = time_difference[:days]

      summary = +""
      summary << "#{months}m" if months > 0

      if date.day != today.day
        summary << "#{weeks}w" if weeks > 0
        summary << "#{days}d" if days > 0
      end
    else
      remainder = (day_count % 7).to_i

      summary =
        if remainder > 0
          if week_count > 0
            "#{week_count}w#{remainder}d"
          else
            "#{remainder}d"
          end
        else
          "#{week_count}w"
        end
    end

    new(
      id: "_for_duration_#{date}",
      starts_at: today.to_time,
      ends_at: (today + 1.day).to_time,
      icon: icon,
      summary: summary
    )
  end

  def initialize(
    starts_at:,
    ends_at:,
    summary:,
    description: nil,
    icon: nil,
    location: nil,
    daily: false,
    id: SecureRandom.hex
  )
    @id, @icon, @summary, @description, @location, @daily =
      id, icon, summary.gsub(/[^a-zA-Z0-9\.\-\"\ \_\°\/\\\&\:\+\,\?\(\)\<\>\'’@#]/, ""), description, location, daily

    @starts_at = case starts_at
    when Integer
      Time.at(starts_at).in_time_zone(Timeframe::Application.config.local["timezone"])
    when String
      ActiveSupport::TimeZone[
          Timeframe::Application.config.local["timezone"]
        ].parse(starts_at)
    else
      starts_at
    end

    @ends_at = case ends_at
    when Integer
      Time.at(ends_at).in_time_zone(Timeframe::Application.config.local["timezone"])
    when String
      ActiveSupport::TimeZone[
          Timeframe::Application.config.local["timezone"]
        ].parse(ends_at)
    else
      ends_at
    end
  end

  def daily?
    length_in_seconds = end_i - start_i

    return false if length_in_seconds == 0
    return false unless @starts_at.hour == 0 && @ends_at.hour == 0

    true
  end

  def private?
    @summary == "timeframe-private" || @description == "timeframe-private"
  end

  def omit?
    @summary.blank? || @description&.include?("timeframe-omit") || false
  end

  def start_i
    @starts_at.to_i
  end

  def end_i
    @ends_at.to_i
  end

  def multi_day?
    ((end_i - start_i) > DAY_IN_SECONDS)
  end

  def time
    @time ||= begin
      start = Time.at(start_i).in_time_zone(Timeframe::Application.config.local["timezone"])

      if start_i == end_i
        label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
        suffix = start.strftime("%p").gsub("AM", "a").gsub("PM", "p")

        return "#{label}#{suffix}"
      end

      endtime = Time.at(end_i).in_time_zone(Timeframe::Application.config.local["timezone"])

      # If the time is not the top of the hour, include the minutes past the hour in the label (4:01 vs. 4)
      start_label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
      end_label = endtime.min.positive? ? endtime.strftime("%-l:%M%p") : endtime.strftime("%-l%p")

      # If the event starts and ends on different halves of the day (9am to 3pm),
      # include the suffix for the starting time (am)
      start_suffix =
        if start.strftime("%p") == endtime.strftime("%p") && start.to_date == endtime.to_date
          ""
        else
          start.strftime("%p").gsub("AM", "a").gsub("PM", "p")
        end
      start_date = ""
      end_date = ""

      if start.to_date != endtime.to_date
        start_date = "#{start.strftime("%a")} "
        end_date = "#{endtime.strftime("%a")} "

        "#{start_date}#{start_label}#{start_suffix} -<br />#{end_date}#{end_label.gsub("AM", "a").gsub("PM", "p")}"
      else
        "#{start_date}#{start_label}#{start_suffix} - #{end_date}#{end_label.gsub("AM", "a").gsub("PM", "p")}"
      end
    end
  end

  def summary(as_of = nil)
    if (1900..2100).cover?(@description.to_s.to_i)
      counter = Date.today.year - @description.to_s.to_i

      "#{@summary} (#{counter})"
    elsif multi_day? && as_of
      numerator = (as_of.to_date - @starts_at.to_date).to_i + 1
      denominator = (@ends_at.to_date - @starts_at.to_date).to_i

      "#{@summary} (#{numerator}/#{denominator})"
    else
      @summary
    end.gsub(/\p{Emoji_Presentation}/, "").strip
  end
end

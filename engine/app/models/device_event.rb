class DeviceEvent
  DAY_IN_SECONDS = 86_400

  attr_reader :id, :starts_at, :ends_at, :multi_day, :location, :icon_rotation
  attr_accessor :icon

  def initialize(
    starts_at:,
    ends_at:,
    summary:,
    timezone: "UTC",
    description: nil,
    icon: nil,
    icon_rotation: nil,
    location: nil,
    daily: false,
    id: SecureRandom.hex
  )
    @id, @icon, @icon_rotation, @summary, @description, @location, @daily, @timezone =
      id, icon, icon_rotation, summary.gsub(/[^a-zA-Z0-9.\-"\  _°\/\\&:+,?()<>'@#\u2019]/, ""), description, location, daily, timezone

    @starts_at = case starts_at
    when Integer
      Time.at(starts_at).in_time_zone(@timezone)
    when String
      ActiveSupport::TimeZone[@timezone].parse(starts_at)
    else
      starts_at
    end

    @ends_at = case ends_at
    when Integer
      Time.at(ends_at).in_time_zone(@timezone)
    when String
      ActiveSupport::TimeZone[@timezone].parse(ends_at)
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
    (end_i - start_i) > if starts_at.to_time.dst? && !ends_at.to_time.dst?
      (DAY_IN_SECONDS + 3600)
    else
      DAY_IN_SECONDS
    end
  end

  def weather?
    id.to_s.match?(/\A_(?:ha|wk)_weather_/)
  end

  def weather_hourly?
    start_i == end_i && weather?
  end

  def start_time
    start = Time.at(start_i).in_time_zone(@timezone)
    label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
    suffix = start.strftime("%p").gsub("AM", "a").gsub("PM", "p")
    "#{label}#{suffix}"
  end

  def time
    @time ||= begin
      start = Time.at(start_i).in_time_zone(@timezone)

      if start_i == end_i
        label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
        suffix = start.strftime("%p").gsub("AM", "a").gsub("PM", "p")

        return "#{label}#{suffix}"
      end

      endtime = Time.at(end_i).in_time_zone(@timezone)

      start_label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
      end_label = endtime.min.positive? ? endtime.strftime("%-l:%M%p") : endtime.strftime("%-l%p")

      start_suffix =
        if start.strftime("%p") == endtime.strftime("%p") && start.to_date == endtime.to_date
          ""
        else
          start.strftime("%p").gsub("AM", "a").gsub("PM", "p")
        end
      start_date = ""
      end_date = ""

      if start.to_date != endtime.to_date
        start_date = "#{short_weekday_label(start)} "
        end_date = "#{short_weekday_label(endtime)} "
      end

      "#{start_date}#{start_label}#{start_suffix} - #{end_date}#{end_label.gsub("AM", "a").gsub("PM", "p")}"
    end
  end

  def short_weekday_label(value)
    %w[Su M Tu W Th F Sa][value.wday]
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

  def as_json(date: nil)
    {
      icon_text: icon&.start_with?("alpha-") ? icon.delete_prefix("alpha-").upcase : nil,
      icon_class: icon&.start_with?("alpha-") ? nil : icon,
      icon_style: icon_rotation ? "display: inline-block; transform: rotate(#{icon_rotation + 180}deg); " : nil,
      summary: summary(date),
      location: location,
      time_html: time.to_s,
      start_time: start_time
    }
  end
end

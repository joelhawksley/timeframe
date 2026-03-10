# copied from https://github.com/tmlee/time_difference/pull/40

require "active_support/all"

class TimeDifference
  private_class_method :new

  TIME_COMPONENTS = [:years, :months, :weeks, :days, :hours, :minutes, :seconds]

  def self.between(start_time, end_time)
    new(start_time, end_time)
  end

  def in_years
    in_component(:years)
  end

  def in_months
    months_between(@start_time, @end_time)
  end

  def in_weeks
    in_component(:weeks)
  end

  def in_days
    in_component(:days)
  end

  def in_hours
    in_component(:hours)
  end

  def in_minutes
    in_component(:minutes)
  end

  def in_seconds
    @time_diff
  end

  def in_each_component
    TIME_COMPONENTS.map do |time_component|
      [time_component, public_send(:"in_#{time_component}")]
    end.to_h
  end

  def in_general
    remaining = @time_diff
    TIME_COMPONENTS.map do |time_component|
      if remaining > 0
        rounded_time_component = (remaining / 1.send(time_component).seconds).round(2).floor
        remaining -= rounded_time_component.send(time_component)
        [time_component, rounded_time_component]
      else
        [time_component, 0]
      end
    end.to_h
  end

  def humanize
    diff_parts = []
    in_general.each do |part, quantity|
      next if quantity <= 0
      part = part.to_s.humanize

      if quantity <= 1
        part = part.singularize
      end

      diff_parts << "#{quantity} #{part}"
    end

    last_part = diff_parts.pop
    if diff_parts.empty?
      last_part
    else
      [diff_parts.join(", "), last_part].join(" and ")
    end
  end

  private

  def initialize(start_time, end_time)
    @start_time = start_time.to_time
    @end_time = end_time.to_time

    start_time_s = time_in_seconds(start_time)
    end_time_s = time_in_seconds(end_time)

    @time_diff = (end_time_s - start_time_s).abs
  end

  def time_in_seconds(time)
    time.to_time.to_f
  end

  def in_component(component)
    (@time_diff / 1.send(component)).round(2)
  end

  def months_between(t1, t2)
    months_excl_days = (t2.year * 12 + t2.month) - (t1.year * 12 + t1.month)
    if t2.day > t1.day
      months_excl_days
    elsif t2.day < t1.day
      months_excl_days - 1
    elsif t2.seconds_since_midnight >= t1.seconds_since_midnight
      months_excl_days
    else
      months_excl_days - 1
    end
  end
end

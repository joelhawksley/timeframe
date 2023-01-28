# frozen_string_literal: true

class Value < ApplicationRecord
  def self.weather
    find_by_key("weather").value
  end

  def self.calendar_events
    find_by_key("calendar_events").value
  end

  def self.sorted_calendar_events_array
    calendar_events.values.flatten.map(&:values).flatten.sort_by { |event| event[:start_i] }
  end
end

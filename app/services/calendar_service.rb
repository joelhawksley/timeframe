# frozen_string_literal: true

class CalendarService
  def self.baby_age_string(birthdate = Timeframe::Application.config.local["birthdate"])
    day_count = Date.today - Date.parse(birthdate)
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

    if remainder > 0
      "#{week_count}w#{remainder}d"
    else
      "#{week_count}w"
    end
  end
end
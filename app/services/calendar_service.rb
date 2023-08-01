# frozen_string_literal: true

class CalendarService
  def self.baby_age_string(birthdate = Date.parse(Timeframe::Application.config.local["birthdate"]))
    day_count = Date.today - birthdate
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

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
end
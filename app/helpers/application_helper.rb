# frozen_string_literal: true

module ApplicationHelper
  def flash_class(level)
    case level
    when :success then "alert alert-success"
    when :error then "alert alert-error"
    when :alert then "alert alert-error"
    else "alert alert-info"
    end
  end

  def pregnancy_string(today = Date.today)
    day_count = today - Date.parse("2022-10-01")
    week_count = (day_count / 7).to_i
    remainder = (day_count % 7).to_i

    "#{week_count}w#{remainder}d"
  end
end

# frozen_string_literal: true

# Service for generating the date/time label for an event.
# Such as "4p", "2 - 4a", "9a - 3p"
class EventTimeService
  def self.call(start_i, end_i, tz)
    start = Time.at(start_i).in_time_zone(tz)
    endtime = Time.at(end_i).in_time_zone(tz)

    if start_i == end_i
      label = start.min.positive? ? start.strftime("%-l:%M") : start.strftime("%-l")
      suffix = start.strftime("%p").gsub("AM", "a").gsub("PM", "p")

      "#{label}#{suffix}"
    else
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
end

module Demo
  class CalendarFeed < CalendarFeed
    def baby_age_event(date, icon)
      super(Date.parse(date) - 39.days, icon)
    end
  end
end

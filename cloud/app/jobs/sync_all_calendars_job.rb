# frozen_string_literal: true

class SyncAllCalendarsJob < ApplicationJob
  queue_as :default

  def perform
    Calendar.find_each do |calendar|
      if calendar.google?
        SyncGoogleCalendarJob.perform_later(calendar.id)
      elsif calendar.url?
        SyncIcsCalendarJob.perform_later(calendar.id)
      end
    end
  end
end

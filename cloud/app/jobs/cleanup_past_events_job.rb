# frozen_string_literal: true

class CleanupPastEventsJob < ApplicationJob
  queue_as :default

  def perform
    CalendarEvent.where("ends_at < ?", Time.current.beginning_of_day).delete_all
  end
end

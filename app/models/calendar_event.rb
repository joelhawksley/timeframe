# frozen_string_literal: true

class CalendarEvent < ActiveRecord::Base
  belongs_to :calendar

  encrypts :title
  encrypts :description
  encrypts :location

  validates :external_id, presence: true, uniqueness: {scope: :calendar_id}
  validates :starts_at, presence: true
  validates :ends_at, presence: true

  scope :future, -> { where("ends_at >= ?", Time.current) }
  scope :past, -> { where("ends_at < ?", Time.current) }
  scope :upcoming, ->(days = 40) { where(starts_at: ..days.days.from_now) }
end

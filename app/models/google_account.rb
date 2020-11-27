class GoogleAccount < ApplicationRecord
  belongs_to :user
  has_many :google_calendars
end
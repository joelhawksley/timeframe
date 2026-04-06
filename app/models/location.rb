# frozen_string_literal: true

class Location < ActiveRecord::Base
  belongs_to :account
  has_many :devices, dependent: :restrict_with_error

  encrypts :name
  encrypts :latitude
  encrypts :longitude

  validates :name, presence: true
  validates :latitude, presence: true, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}
  validates :longitude, presence: true, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}
  validates :time_zone, presence: true
end

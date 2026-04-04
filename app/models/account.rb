# frozen_string_literal: true

class Account < ActiveRecord::Base
  encrypts :name

  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :locations, dependent: :restrict_with_error
  has_many :devices, through: :locations
  has_many :google_accounts, dependent: :destroy
  has_many :calendars, dependent: :destroy
  has_many :calendar_events, through: :calendars
  has_many :audit_logs, through: :users

  validates :name, presence: true
end

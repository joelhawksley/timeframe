# frozen_string_literal: true

class Account < ActiveRecord::Base
  encrypts :name

  has_many :account_users, dependent: :destroy
  has_many :users, through: :account_users
  has_many :locations, dependent: :restrict_with_error
  has_many :devices, through: :locations

  validates :name, presence: true
end

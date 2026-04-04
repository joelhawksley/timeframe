# frozen_string_literal: true

class User < ActiveRecord::Base
  devise :magic_link_authenticatable, :rememberable

  encrypts :email, deterministic: true
  encrypts :magic_link_nonce
  encrypts :remember_token

  has_many :account_users, dependent: :destroy
  has_many :accounts, through: :account_users
  has_many :audit_logs, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: {with: URI::MailTo::EMAIL_REGEXP}
end

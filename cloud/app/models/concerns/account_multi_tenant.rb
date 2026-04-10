# frozen_string_literal: true

# Extends core Account with multi-tenant associations
module AccountMultiTenant
  extend ActiveSupport::Concern

  included do
    has_many :google_accounts, dependent: :destroy
    has_many :calendars, dependent: :destroy
    has_many :calendar_events, through: :calendars
    has_many :audit_logs, through: :users
  end
end

Account.include(AccountMultiTenant)

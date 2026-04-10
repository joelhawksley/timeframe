# frozen_string_literal: true

class AuditLog < ActiveRecord::Base
  belongs_to :user, optional: true
  belongs_to :subject, polymorphic: true

  validates :event_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
end

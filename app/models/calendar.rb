# frozen_string_literal: true

class Calendar < ActiveRecord::Base
  belongs_to :account
  belongs_to :google_account, optional: true
  has_many :calendar_events, dependent: :destroy

  before_destroy :stop_webhook!, if: :google?

  validates :name, presence: true
  validates :source_type, presence: true, inclusion: {in: %w[google url]}
  validates :url, presence: true, if: -> { source_type == "url" }
  validates :url, uniqueness: {scope: :account_id}, if: -> { source_type == "url" && url.present? }
  validates :external_id, presence: true, if: -> { source_type == "google" }
  validate :url_is_valid_ics, on: :create, if: -> { source_type == "url" && url.present? }

  after_create :sync_now, if: -> { source_type == "url" }

  scope :google, -> { where(source_type: "google") }
  scope :url_source, -> { where(source_type: "url") }
  scope :with_expiring_webhooks, -> { google.where("webhook_expires_at < ?", 1.day.from_now).where.not(webhook_channel_id: nil) }
  scope :without_webhooks, -> { google.where(webhook_channel_id: nil) }

  def google?
    source_type == "google"
  end

  def url?
    source_type == "url"
  end

  def sync!
    if google?
      SyncGoogleCalendarJob.perform_later(id)
    elsif url?
      SyncIcsCalendarJob.perform_later(id)
    end
  end

  def register_webhook!
    return unless google? && google_account

    stop_webhook! if webhook_channel_id.present?

    channel_id = SecureRandom.uuid
    callback_url = "#{ENV.fetch("APP_HOST")}webhooks/google_calendar"

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = google_account.valid_access_token

    channel = Google::Apis::CalendarV3::Channel.new(
      id: channel_id,
      type: "web_hook",
      address: callback_url,
      token: webhook_verification_token,
      expiration: 7.days.from_now.to_i * 1000 # milliseconds
    )

    response = service.watch_event(external_id, channel)

    update!(
      webhook_channel_id: response.id,
      webhook_resource_id: response.resource_id,
      webhook_expires_at: Time.at(response.expiration.to_i / 1000)
    )
  rescue => e
    Rails.logger.error("[Webhook] Failed to register for calendar #{id}: #{e.message}")
  end

  def stop_webhook!
    return unless webhook_channel_id.present? && webhook_resource_id.present? && google_account

    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = google_account.valid_access_token

    channel = Google::Apis::CalendarV3::Channel.new(
      id: webhook_channel_id,
      resource_id: webhook_resource_id
    )

    service.stop_channel(channel)
  rescue => e
    Rails.logger.warn("[Webhook] Failed to stop channel #{webhook_channel_id}: #{e.message}")
  ensure
    update!(webhook_channel_id: nil, webhook_resource_id: nil, webhook_expires_at: nil)
  end

  def webhook_verification_token
    OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "calendar-#{id}")
  end

  private

  def sync_now
    SyncIcsCalendarJob.perform_now(id)
  end

  def url_is_valid_ics
    response = HTTParty.get(url, timeout: 10)
    calendars = Icalendar::Calendar.parse(response.body)
    errors.add(:url, "could not be loaded as a valid ICS calendar") if calendars.empty?
  rescue => e
    errors.add(:url, "could not be loaded: #{e.message}")
  end
end

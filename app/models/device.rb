# frozen_string_literal: true

class Device < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  SUPPORTED_MODELS = {
    "visionect_13" => {name: "Visionect Place & Play 13\"", template: "thirteen", width: 1200, height: 1600},
    "boox_mira_pro" => {name: "Boox Mira Pro 25.3\"", template: "mira", width: 1800, height: 3200},
    "trmnl_og" => {name: "TRMNL (OG)", template: "trmnl", width: 480, height: 800}
  }.freeze

  belongs_to :location, optional: true

  has_one :account, through: :location

  encrypts :mac_address, deterministic: true
  encrypts :api_key, deterministic: true
  encrypts :visionect_serial, deterministic: true
  encrypts :display_key, deterministic: true
  encrypts :session_token, deterministic: true
  encrypts :cached_image

  validates :name, presence: true, uniqueness: true
  validates :model, presence: true, inclusion: {in: SUPPORTED_MODELS.keys}
  validates :mac_address, uniqueness: true, allow_nil: true
  validates :mac_address, presence: true, if: :trmnl?
  validates :visionect_serial, uniqueness: true, allow_nil: true

  before_create :generate_api_key, if: :trmnl?
  before_create :generate_friendly_id, if: :trmnl?
  before_create :generate_confirmation_code, unless: :visionect?
  before_create :generate_display_key, if: :visionect?
  before_create :auto_confirm!, if: :visionect?

  def model_name_label
    SUPPORTED_MODELS.dig(model, :name)
  end

  def display_width
    SUPPORTED_MODELS.dig(model, :width)
  end

  def display_height
    SUPPORTED_MODELS.dig(model, :height)
  end

  def trmnl?
    model == "trmnl_og"
  end

  def confirmed?
    confirmed_at.present?
  end

  def disconnected?
    last_connection_at.nil? || last_connection_at < 1.hour.ago
  end

  def rotate_session_token!
    update!(session_token: SecureRandom.urlsafe_base64(32))
    session_token
  end

  def pending_confirmation?
    confirmation_code.present? && !confirmed?
  end

  def confirm!(location, name: nil)
    attrs = {location: location, confirmed_at: Time.current, confirmation_code: nil}
    attrs[:name] = name if name.present?
    update!(attrs)
  end

  def visionect?
    model == "visionect_13"
  end

  def regenerate_display_key!
    update!(display_key: SecureRandom.alphanumeric(24))
  end

  def token_display_url(host:)
    "#{host}/d/#{id}?key=#{display_key}"
  end

  def signed_screenshot_url(host:)
    sgid = to_sgid(expires_in: 1.minute, for: "screenshot").to_s
    "#{host}/signed_screenshot/#{sgid}"
  end

  def refresh_screenshot!(base_url = nil)
    base_url ||= "http://localhost:#{ENV.fetch("PORT", 3000)}"
    url = if visionect?
      token_display_url(host: base_url)
    else
      account_location_device_url(account_id: account.id, location_id: location.id, id: id, host: base_url)
    end

    self.cached_image = if visionect?
      # Capture raw PNG in portrait orientation (1200×1600).
      # ImageEncoder.png_to_4bpp handles grayscale conversion, dithering,
      # and 90° rotation to the panel's native landscape layout (1600×1200).
      ScreenshotService.capture(
        url,
        width: display_width, height: display_height,
        raw: true
      )
    else
      ScreenshotService.capture(url)
    end

    self.cached_image_at = Time.current
    save!

    # Pre-encode 4bpp data for the protocol server so device connections are instant
    encode_visionect_image! if visionect?
  end

  def encode_visionect_image!
    return unless visionect? && cached_image.present?

    png_data = Base64.decode64(cached_image)
    raw_4bpp = VisionectProtocol::ImageEncoder.png_to_4bpp(png_data)
    VisionectProtocol::Server.store_image(id, raw_4bpp)
  rescue => e
    Rails.logger.error "[Visionect] Image encoding failed for #{name}: #{e.message}"
  end

  def self.refresh_all_screenshots!(base_url = nil)
    base_url ||= "http://localhost:#{ENV.fetch("PORT", 3000)}"
    where(model: "trmnl_og").find_each do |device|
      device.refresh_screenshot!(base_url)
    rescue => e
      Rails.logger.error "[Screenshot] Failed for #{device.name}: #{e.message}"
    end
  end

  def authenticate_api_key(token)
    api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, token.to_s)
  end

  # Auto-provision a Visionect device from its serial number
  def self.find_or_create_by_visionect_serial(serial)
    device = find_by(visionect_serial: serial)
    return device if device

    create!(
      name: "Visionect #{serial}",
      model: "visionect_13",
      visionect_serial: serial
    )
  rescue ActiveRecord::RecordNotUnique
    find_by(visionect_serial: serial)
  end

  def record_visionect_connection!
    update_column(:last_connection_at, Time.current)
  end

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(16)
  end

  def generate_friendly_id
    self.friendly_id ||= SecureRandom.alphanumeric(6).upcase
  end

  def generate_confirmation_code
    self.confirmation_code ||= SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
  end

  def generate_display_key
    self.display_key ||= SecureRandom.alphanumeric(24)
  end

  def auto_confirm!
    self.confirmed_at ||= Time.current
  end
end

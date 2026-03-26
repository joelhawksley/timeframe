# frozen_string_literal: true

class Device < ActiveRecord::Base
  SUPPORTED_MODELS = {
    "visionect_13" => {name: "Visionect Place & Play 13\"", template: "thirteen", width: 1200, height: 1600},
    "boox_mira_pro" => {name: "Boox Mira Pro 25.3\"", template: "mira", width: 1800, height: 3200},
    "trmnl_og" => {name: "TRMNL (OG)", template: "trmnl", width: 480, height: 800}
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :model, presence: true, inclusion: {in: SUPPORTED_MODELS.keys}
  validates :mac_address, uniqueness: true, allow_nil: true
  validates :mac_address, presence: true, if: :trmnl?
  validates :visionect_serial, uniqueness: true, allow_nil: true

  before_create :generate_api_key, if: :trmnl?
  before_create :generate_friendly_id, if: :trmnl?

  def model_name_label
    SUPPORTED_MODELS.dig(model, :name)
  end

  def slug
    name.parameterize(separator: "_")
  end

  def display_path
    "/accounts/me/displays/#{slug}"
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

  def visionect?
    model == "visionect_13"
  end

  def refresh_screenshot!(base_url = nil)
    base_url ||= "http://localhost:#{ENV.fetch("PORT", 3000)}"
    display_url = "#{base_url}#{display_path}"

    self.cached_image = if visionect?
      # Capture raw PNG in portrait orientation (1200×1600).
      # ImageEncoder.png_to_4bpp handles grayscale conversion, dithering,
      # and 90° rotation to the panel's native landscape layout (1600×1200).
      ScreenshotService.capture(
        display_url,
        width: display_width, height: display_height,
        raw: true
      )
    else
      ScreenshotService.capture(display_url)
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
    where(model: ["trmnl_og", "visionect_13"]).find_each do |device|
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
end

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

  def refresh_screenshot!(base_url)
    display_url = "#{base_url}#{display_path}"
    self.cached_image = ScreenshotService.capture(display_url)
    self.cached_image_at = Time.current
    save!
  end

  def authenticate_api_key(token)
    api_key.present? && ActiveSupport::SecurityUtils.secure_compare(api_key, token.to_s)
  end

  private

  def generate_api_key
    self.api_key ||= SecureRandom.hex(16)
  end

  def generate_friendly_id
    self.friendly_id ||= SecureRandom.alphanumeric(6).upcase
  end
end

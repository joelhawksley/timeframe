# frozen_string_literal: true

class PendingDevice < ActiveRecord::Base
  belongs_to :claimed_device, class_name: "Device", optional: true

  encrypts :mac_address, deterministic: true
  encrypts :pairing_code, deterministic: true
  encrypts :api_key

  validates :pairing_code, uniqueness: true, allow_nil: true

  before_create :generate_pairing_code

  def claimed?
    claimed_device_id.present?
  end

  def claim!(location:, name:, model:)
    device = Device.create!(
      name: name,
      model: model,
      location: location,
      mac_address: mac_address,
      api_key: api_key,
      friendly_id: friendly_id,
      confirmed_at: Time.current
    )
    update!(claimed_device: device)
    device
  end

  private

  def generate_pairing_code
    self.pairing_code ||= SecureRandom.alphanumeric(6).upcase
  end
end

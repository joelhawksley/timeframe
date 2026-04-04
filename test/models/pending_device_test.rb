# frozen_string_literal: true

require "test_helper"

class PendingDeviceTest < Minitest::Test
  def test_claimed_returns_false_when_unclaimed
    pd = PendingDevice.create!
    refute pd.claimed?
  end

  def test_claimed_returns_true_when_claimed
    mac = "EE:FF:#{SecureRandom.hex(4).scan(/../).join(":").upcase}"
    pd = PendingDevice.create!(mac_address: mac, api_key: SecureRandom.hex(16), friendly_id: SecureRandom.alphanumeric(6).upcase)
    pd.claim!(location: test_location, name: "Claimed #{SecureRandom.hex(4)}", model: "trmnl_og")
    assert pd.claimed?
  end
end

# frozen_string_literal: true

require "test_helper"

class DeviceBroadcasterTest < Minitest::Test
  def setup
    PendingDevice.where.not(claimed_device_id: nil).update_all(claimed_device_id: nil)
    Device.where("name LIKE 'test_broadcast_%'").destroy_all
    Device.where(model: ["boox_mira_pro", "boox_mira"]).destroy_all
    DeviceBroadcaster.clear_hash(:all)
  end

  def test_broadcast_if_changed_broadcasts_on_first_call
    device = create_device("test_broadcast_first")
    broadcasts = track_broadcasts do
      DeviceBroadcaster.broadcast_if_changed(device)
    end

    assert_equal 1, broadcasts.size
    assert_equal device, broadcasts.first[:device]
    assert_equal "refresh", broadcasts.first[:data][:action]
  end

  def test_broadcast_if_changed_skips_when_unchanged
    device = create_device("test_broadcast_skip")
    broadcasts = track_broadcasts do
      DeviceBroadcaster.broadcast_if_changed(device)
      DeviceBroadcaster.broadcast_if_changed(device)
    end

    assert_equal 1, broadcasts.size
  end

  def test_broadcast_if_changed_rebroadcasts_after_clear_hash
    device = create_device("test_broadcast_clear")
    broadcasts = track_broadcasts do
      DeviceBroadcaster.broadcast_if_changed(device)
      DeviceBroadcaster.clear_hash(device.id)
      DeviceBroadcaster.broadcast_if_changed(device)
    end

    assert_equal 2, broadcasts.size
  end

  def test_broadcast_all_mira_devices_broadcasts_mira_devices
    device = Device.create!(location: test_location, name: "test_broadcast_mira", model: "boox_mira_pro")
    device.update_column(:demo_mode_enabled, true)
    broadcasts = track_broadcasts do
      DeviceBroadcaster.broadcast_all_mira_devices
    end

    assert_equal 1, broadcasts.size
    assert_equal device, broadcasts.first[:device]
  ensure
    device&.destroy
  end

  def test_broadcast_all_mira_devices_includes_boox_mira
    device = Device.create!(location: test_location, name: "test_broadcast_boox_mira", model: "boox_mira")
    device.update_column(:demo_mode_enabled, true)
    broadcasts = track_broadcasts do
      DeviceBroadcaster.broadcast_all_mira_devices
    end

    assert_equal 1, broadcasts.size
    assert_equal device, broadcasts.first[:device]
  ensure
    device&.destroy
  end

  def test_broadcast_all_mira_devices_handles_errors
    Device.create!(location: test_location, name: "test_broadcast_err", model: "boox_mira_pro")

    DeviceBroadcaster.stub(:view_object_for, ->(_) { raise "boom" }) do
      # Should not raise
      DeviceBroadcaster.broadcast_all_mira_devices
    end

    assert true
  ensure
    Device.where(name: "test_broadcast_err").destroy_all
  end

  private

  def create_device(name)
    device = Device.create!(location: test_location, name: name, model: "visionect_13", visionect_serial: "BC#{SecureRandom.hex(3).upcase}")
    device.update_column(:demo_mode_enabled, true)
    device
  end

  def track_broadcasts(&block)
    broadcasts = []
    DeviceChannel.stub(:broadcast_to, ->(device, data) { broadcasts << {device: device, data: data} }) do
      block.call
    end
    broadcasts
  end
end

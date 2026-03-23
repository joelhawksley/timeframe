# frozen_string_literal: true

require "test_helper"

class DeviceTest < Minitest::Test
  def setup
    Device.where(model: "visionect_13").destroy_all
  end

  def test_model_name_label
    device = Device.new(name: "test", model: "visionect_13")
    assert_equal "Visionect Place & Play 13\"", device.model_name_label
  end

  def test_display_width
    device = Device.new(name: "test", model: "visionect_13")
    assert_equal 1200, device.display_width
  end

  def test_display_height
    device = Device.new(name: "test", model: "visionect_13")
    assert_equal 1600, device.display_height
  end

  def test_find_or_create_by_visionect_serial_creates_new_device
    device = Device.find_or_create_by_visionect_serial("ABC123")

    assert_equal "Visionect ABC123", device.name
    assert_equal "visionect_13", device.model
    assert_equal "ABC123", device.visionect_serial
  end

  def test_find_or_create_by_visionect_serial_returns_existing_device
    existing = Device.create!(name: "Visionect ABC123", model: "visionect_13", visionect_serial: "ABC123")

    device = Device.find_or_create_by_visionect_serial("ABC123")

    assert_equal existing.id, device.id
  end

  def test_find_or_create_by_visionect_serial_handles_race_condition
    existing = Device.create!(name: "Visionect RACE1", model: "visionect_13", visionect_serial: "RACE1")

    # Simulate race: find_by returns nil first time, then create! hits unique constraint,
    # then find_by succeeds in the rescue block
    call_count = 0
    original_find_by = Device.method(:find_by)

    Device.stub(:find_by, ->(*args, **kwargs) {
      call_count += 1
      (call_count == 1) ? nil : original_find_by.call(*args, **kwargs)
    }) do
      Device.stub(:create!, ->(*) { raise ActiveRecord::RecordNotUnique }) do
        device = Device.find_or_create_by_visionect_serial("RACE1")
        assert_equal existing.id, device.id
      end
    end
  end

  def test_record_visionect_connection
    device = Device.create!(name: "test_conn", model: "visionect_13", visionect_serial: "CONN1")

    assert_nil device.last_connection_at

    device.record_visionect_connection!
    device.reload

    assert_in_delta Time.current, device.last_connection_at, 2
  end
end

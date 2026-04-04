# frozen_string_literal: true

require "test_helper"

class DeviceTest < Minitest::Test
  def setup
    # Clean up all test-created devices to avoid uniqueness conflicts across tests
    Device.where("name LIKE 'test_%' OR name LIKE 'Visionect %'").destroy_all
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
    existing = Device.create!(location: test_location, name: "Visionect ABC123", model: "visionect_13", visionect_serial: "ABC123")

    device = Device.find_or_create_by_visionect_serial("ABC123")

    assert_equal existing.id, device.id
  end

  def test_find_or_create_by_visionect_serial_handles_race_condition
    existing = Device.create!(location: test_location, name: "Visionect RACE1", model: "visionect_13", visionect_serial: "RACE1")

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
    device = Device.create!(location: test_location, name: "test_conn", model: "visionect_13", visionect_serial: "CONN1")

    assert_nil device.last_connection_at

    device.record_visionect_connection!
    device.reload

    assert_in_delta Time.current, device.last_connection_at, 2
  end

  def test_encode_visionect_image_stores_4bpp_data
    device = Device.create!(location: test_location, name: "test_encode", model: "visionect_13", visionect_serial: "ENC1")
    # Create a small white PNG via ImageMagick
    png = generate_test_png
    device.update!(cached_image: Base64.strict_encode64(png))

    device.encode_visionect_image!

    stored = VisionectProtocol::Server.fetch_image(device.id)
    assert_equal 960_000, stored.bytesize
  end

  def test_encode_visionect_image_skips_non_visionect
    device = Device.create!(location: test_location, name: "test_trmnl", model: "trmnl_og", mac_address: "FF:EE:DD:CC:BB:AA")
    device.encode_visionect_image!

    assert_nil VisionectProtocol::Server.fetch_image(device.id)
  end

  def test_encode_visionect_image_skips_without_cached_image
    device = Device.create!(location: test_location, name: "test_nocache", model: "visionect_13", visionect_serial: "NC1")
    device.encode_visionect_image!

    assert_nil VisionectProtocol::Server.fetch_image(device.id)
  end

  def test_refresh_all_screenshots_calls_refresh_on_each_device
    Device.create!(location: test_location, name: "test_refresh_all", model: "visionect_13", visionect_serial: "RA1")
    refreshed_ids = []

    original_method = Device.instance_method(:refresh_screenshot!)
    Device.define_method(:refresh_screenshot!) { |*| refreshed_ids << id }

    Device.refresh_all_screenshots!
    assert refreshed_ids.any?
  ensure
    Device.define_method(:refresh_screenshot!, original_method)
  end

  def test_refresh_all_screenshots_handles_errors_gracefully
    Device.create!(location: test_location, name: "test_error", model: "visionect_13", visionect_serial: "ERR1")

    original_method = Device.instance_method(:refresh_screenshot!)
    Device.define_method(:refresh_screenshot!) { |*| raise "test error" }

    # Should not raise
    Device.refresh_all_screenshots!
    assert true
  ensure
    Device.define_method(:refresh_screenshot!, original_method)
  end

  def test_confirm_sets_location_and_confirmed_at
    device = Device.create!(name: "test_confirm_#{SecureRandom.hex(4)}", model: "trmnl_og", mac_address: "AA:BB:#{SecureRandom.hex(4).scan(/../).join(":").upcase}", api_key: SecureRandom.hex(16), friendly_id: SecureRandom.alphanumeric(6).upcase)
    assert device.pending_confirmation?

    device.confirm!(test_location)
    device.reload

    assert device.confirmed?
    refute device.pending_confirmation?
    assert_equal test_location, device.location
    assert_nil device.confirmation_code
  end

  def test_confirm_with_name_updates_name
    device = Device.create!(name: "test_confirm_name_#{SecureRandom.hex(4)}", model: "trmnl_og", mac_address: "BB:CC:#{SecureRandom.hex(4).scan(/../).join(":").upcase}", api_key: SecureRandom.hex(16), friendly_id: SecureRandom.alphanumeric(6).upcase)
    new_name = "Renamed #{SecureRandom.hex(4)}"
    device.confirm!(test_location, name: new_name)
    device.reload

    assert_equal new_name, device.name
  end

  private

  def generate_test_png
    require "mini_magick"
    img = MiniMagick::Image.create(".png") do |f|
      system("magick", "-size", "1600x1200", "xc:white", f.path,
        out: File::NULL, err: File::NULL)
    end
    img.to_blob
  end
end

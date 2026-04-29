# frozen_string_literal: true

require "test_helper"

class DeviceTest < Minitest::Test
  def setup
    # Clean up all test-created devices to avoid uniqueness conflicts across tests
    PendingDevice.where.not(claimed_device_id: nil).update_all(claimed_device_id: nil)
    Device.where("name LIKE 'test_%' OR name LIKE 'Visionect %' OR name LIKE 'Living Room %'").destroy_all
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
    Device.create!(location: test_location, name: "test_refresh_all", model: "trmnl_og", mac_address: "RA:#{SecureRandom.hex(5).scan(/../).join(":").upcase}", api_key: SecureRandom.hex(16), friendly_id: SecureRandom.alphanumeric(6).upcase)
    refreshed_ids = []

    original_method = Device.instance_method(:refresh_screenshot!)
    Device.define_method(:refresh_screenshot!) { |*| refreshed_ids << id }

    Device.refresh_all_screenshots!
    assert refreshed_ids.any?
  ensure
    Device.define_method(:refresh_screenshot!, original_method)
  end

  def test_refresh_all_screenshots_handles_errors_gracefully
    Device.create!(location: test_location, name: "test_error", model: "trmnl_og", mac_address: "EE:RR:#{SecureRandom.hex(4).scan(/../).join(":").upcase}", api_key: SecureRandom.hex(16), friendly_id: SecureRandom.alphanumeric(6).upcase)

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

  def test_authenticate_session_returns_device_for_valid_token
    device = Device.create!(location: test_location, name: "test_auth_session", model: "visionect_13", visionect_serial: "AUTH1")
    token = device.rotate_session_token!

    result = Device.authenticate_session(device.id, token)
    assert_equal device.id, result.id
  end

  def test_authenticate_session_returns_nil_for_wrong_token
    device = Device.create!(location: test_location, name: "test_auth_bad", model: "visionect_13", visionect_serial: "AUTH2")
    device.rotate_session_token!

    assert_nil Device.authenticate_session(device.id, "wrong-token")
  end

  def test_authenticate_session_returns_nil_for_missing_args
    assert_nil Device.authenticate_session(nil, nil)
    assert_nil Device.authenticate_session(nil, "token")
    assert_nil Device.authenticate_session(999_999, nil)
  end

  def test_authenticate_session_returns_nil_for_nonexistent_device
    assert_nil Device.authenticate_session(999_999, "some-token")
  end

  def test_authenticate_session_returns_nil_when_device_has_no_token
    device = Device.create!(location: test_location, name: "test_auth_notoken", model: "visionect_13", visionect_serial: "AUTH3")

    assert_nil Device.authenticate_session(device.id, "some-token")
  end

  def test_accessible_by_user_who_owns_device
    device = Device.create!(location: test_location, name: "test_access_user", model: "visionect_13", visionect_serial: "ACC1")

    assert device.accessible_by?(user: test_user)
  end

  def test_accessible_by_matching_device
    device = Device.create!(location: test_location, name: "test_access_device", model: "visionect_13", visionect_serial: "ACC2")

    assert device.accessible_by?(device: device)
  end

  def test_not_accessible_by_different_device
    device = Device.create!(location: test_location, name: "test_access_diff", model: "visionect_13", visionect_serial: "ACC3")
    other = Device.create!(location: test_location, name: "test_access_other", model: "visionect_13", visionect_serial: "ACC4")

    refute device.accessible_by?(device: other)
  end

  def test_not_accessible_by_nil
    device = Device.create!(location: test_location, name: "test_access_nil", model: "visionect_13", visionect_serial: "ACC5")

    refute device.accessible_by?
  end

  def test_reterminal_e1003_model_name_label
    device = Device.new(name: "test", model: "reterminal_e1003")
    assert_equal "reTerminal E1003 10.3\"", device.model_name_label
  end

  def test_reterminal_e1003_display_dimensions
    device = Device.new(name: "test", model: "reterminal_e1003")
    assert_equal 1404, device.display_width
    assert_equal 1872, device.display_height
  end

  def test_boox_mira_model_name_label
    device = Device.new(name: "test", model: "boox_mira")
    assert_equal "Boox Mira 13.3\"", device.model_name_label
  end

  def test_boox_mira_display_dimensions
    device = Device.new(name: "test", model: "boox_mira")
    assert_equal 1650, device.display_width
    assert_equal 2200, device.display_height
  end

  def test_boox_mira_predicate
    assert Device.new(model: "boox_mira").boox_mira?
    refute Device.new(model: "visionect_13").boox_mira?
  end

  def test_trmnl_predicate
    assert Device.new(model: "trmnl_og").trmnl?
    refute Device.new(model: "visionect_13").trmnl?
  end

  def test_reterminal_e1001_predicate
    assert Device.new(model: "reterminal_e1001").reterminal_e1001?
    refute Device.new(model: "visionect_13").reterminal_e1001?
  end

  def test_realtime_display
    assert Device.new(model: "boox_mira_pro").realtime_display?
    assert Device.new(model: "boox_mira").realtime_display?
    refute Device.new(model: "visionect_13").realtime_display?
    refute Device.new(model: "trmnl_og").realtime_display?
  end

  def test_pairing_code_device
    assert Device.new(model: "boox_mira_pro").pairing_code_device?
    assert Device.new(model: "boox_mira").pairing_code_device?
    assert Device.new(model: "trmnl_og").pairing_code_device?
    assert Device.new(model: "reterminal_e1003").pairing_code_device?
    refute Device.new(model: "visionect_13").pairing_code_device?
  end

  def test_screenshotted_models_derived_from_supported_models
    assert_includes Device::SCREENSHOTTED_MODELS, "trmnl_og"
    assert_includes Device::SCREENSHOTTED_MODELS, "reterminal_e1001"
    assert_includes Device::SCREENSHOTTED_MODELS, "reterminal_e1003"
    refute_includes Device::SCREENSHOTTED_MODELS, "visionect_13"
    refute_includes Device::SCREENSHOTTED_MODELS, "boox_mira_pro"
    refute_includes Device::SCREENSHOTTED_MODELS, "boox_mira"
  end

  def test_realtime_models_derived_from_supported_models
    assert_includes Device::REALTIME_MODELS, "boox_mira_pro"
    assert_includes Device::REALTIME_MODELS, "boox_mira"
    refute_includes Device::REALTIME_MODELS, "visionect_13"
    refute_includes Device::REALTIME_MODELS, "trmnl_og"
  end

  def test_active_template_for_boox_mira
    device = Device.new(model: "boox_mira", display_template: "default")
    assert_equal "boox_mira", device.active_template
  end

  def test_template_options_returns_hashes
    device = Device.new(model: "trmnl_og")
    options = device.template_options
    assert_kind_of Array, options
    assert options.all? { |t| t.key?(:name) && t.key?(:label) }
    assert_equal "trmnl", options.first[:name]
    assert_equal "Landscape Timeline", options.first[:label]
  end

  def test_template_options_nil_for_single_template_device
    assert_nil Device.new(model: "boox_mira").template_options
    assert_nil Device.new(model: "visionect_13").template_options
  end

  def test_reterminal_e1003_predicate
    device = Device.new(name: "test", model: "reterminal_e1003")
    assert device.reterminal_e1003?
    refute device.trmnl?
    refute device.visionect?
  end

  def test_reterminal_e1003_generates_api_key_and_friendly_id
    device = Device.create!(
      name: "test_reterminal_#{SecureRandom.hex(4)}",
      model: "reterminal_e1003",
      mac_address: "RT:#{SecureRandom.hex(4).scan(/../).join(":").upcase}"
    )
    assert device.api_key.present?
    assert device.friendly_id.present?
    assert device.confirmation_code.present?
    refute device.confirmed?
  end

  def test_reterminal_e1003_requires_mac_address
    device = Device.new(name: "test_rt_no_mac", model: "reterminal_e1003")
    refute device.valid?
    assert device.errors[:mac_address].any?
  end

  def test_active_template_returns_custom_when_set
    device = Device.new(name: "test", model: "trmnl_og", display_template: "three_day")
    assert_equal "three_day", device.active_template
  end

  def test_destroying_device_destroys_associated_pending_device
    device = Device.create!(location: test_location, name: "test_destroy_pending", model: "trmnl_og",
      mac_address: "DE:ST:RO:YP:EN:D1", confirmed_at: Time.current)
    pending = PendingDevice.create!(mac_address: "DE:ST:RO:YP:EN:D1", claimed_device: device)

    assert PendingDevice.exists?(pending.id)
    device.destroy!
    refute PendingDevice.exists?(pending.id)
  end

  private

  def generate_test_png
    require "mini_magick"
    img = MiniMagick::Image.create(".png") do |f|
      MiniMagick.convert do |c|
        c.size "1600x1200"
        c << "xc:white"
        c << f.path
      end
    end
    img.to_blob
  end
end

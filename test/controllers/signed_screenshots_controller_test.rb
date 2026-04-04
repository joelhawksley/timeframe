# frozen_string_literal: true

require "test_helper"

class SignedScreenshotsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @account = test_user.accounts.first
    location = @account.locations.first
    @device = Device.find_or_create_by!(name: "test-signed-screenshot", model: "trmnl_og") do |d|
      d.location = location
      d.mac_address = "AA:BB:CC:DD:EE:77"
    end
    @device.update!(
      confirmed_at: Time.current,
      confirmation_code: nil,
      cached_image: Base64.strict_encode64("fake png data"),
      cached_image_at: Time.current
    )
  end

  test "returns screenshot with valid signed URL" do
    sgid = @device.to_sgid(expires_in: 1.minute, for: "screenshot").to_s
    get "/signed_screenshot/#{sgid}"
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "returns 401 with invalid signed URL" do
    get "/signed_screenshot/invalid-sgid"
    assert_response :unauthorized
    assert_equal "Not authorized", response.body
  end

  test "returns 401 with expired signed URL" do
    sgid = @device.to_sgid(expires_in: 1.second, for: "screenshot").to_s
    travel 2.minutes do
      get "/signed_screenshot/#{sgid}"
      assert_response :unauthorized
    end
  end

  test "returns 401 with wrong purpose" do
    sgid = @device.to_sgid(expires_in: 1.minute, for: "wrong_purpose").to_s
    get "/signed_screenshot/#{sgid}"
    assert_response :unauthorized
  end
end

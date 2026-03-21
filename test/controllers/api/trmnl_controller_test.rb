# frozen_string_literal: true

require "test_helper"

class Api::TrmnlControllerTest < ActionDispatch::IntegrationTest
  def setup
    Device.where(model: "trmnl_og").destroy_all
  end

  # --- /api/setup ---

  test "setup provisions a new device by MAC address" do
    get "/api/setup", headers: {"ID" => "AA:BB:CC:DD:EE:FF"}

    assert_response :success
    json = JSON.parse(response.body)
    assert json["api_key"].present?
    assert json["friendly_id"].present?
    assert_equal "Welcome to Timeframe", json["message"]

    device = Device.find_by(mac_address: "AA:BB:CC:DD:EE:FF")
    assert device.present?
    assert_equal "trmnl_og", device.model
    assert_equal json["api_key"], device.api_key
  end

  test "setup returns existing device for duplicate MAC" do
    get "/api/setup", headers: {"ID" => "AA:BB:CC:DD:EE:FF"}
    first_key = JSON.parse(response.body)["api_key"]

    get "/api/setup", headers: {"ID" => "AA:BB:CC:DD:EE:FF"}
    second_key = JSON.parse(response.body)["api_key"]

    assert_equal first_key, second_key
    assert_equal 1, Device.where(mac_address: "AA:BB:CC:DD:EE:FF").count
  end

  test "setup returns bad request without MAC address" do
    get "/api/setup"
    assert_response :bad_request
  end

  # --- /api/display ---

  test "display succeeds without access token" do
    device = create_trmnl_device!

    ScreenshotService.stub :capture, "fakeimagedatabase64" do
      get "/api/display", headers: {"ID" => device.mac_address}
      assert_response :success
    end
  end

  test "display succeeds with empty access token" do
    device = create_trmnl_device!

    ScreenshotService.stub :capture, "fakeimagedatabase64" do
      get "/api/display", headers: {"ID" => device.mac_address, "ACCESS_TOKEN" => ""}
      assert_response :success
    end
  end

  test "display returns 401 with wrong access token" do
    device = create_trmnl_device!

    get "/api/display", headers: {"ID" => device.mac_address, "ACCESS_TOKEN" => "wrong"}
    assert_response :unauthorized
  end

  test "display returns 401 without MAC address" do
    get "/api/display", headers: {"ACCESS_TOKEN" => "something"}
    assert_response :unauthorized
  end

  test "display auto-provisions unknown MAC" do
    ScreenshotService.stub :capture, "fakeimagedatabase64" do
      get "/api/display", headers: {"ID" => "FF:EE:DD:CC:BB:AA"}
      assert_response :success
      assert Device.find_by(mac_address: "FF:EE:DD:CC:BB:AA").present?
    end
  end

  test "display returns image data for valid device" do
    device = create_trmnl_device!

    ScreenshotService.stub :capture, "fakeimagedatabase64" do
      get "/api/display", headers: {"ID" => device.mac_address, "ACCESS_TOKEN" => device.api_key}

      assert_response :success
      json = JSON.parse(response.body)
      assert_match(/\Adisplay-.*\.png\z/, json["filename"])
      assert json["image_url"].include?("/displays/")
      assert_equal 900, json["refresh_rate"]
      assert_equal "sleep", json["special_function"]
      assert_equal false, json["reset_firmware"]
      assert_equal false, json["update_firmware"]
    end
  end

  test "display skips refresh when cached image exists" do
    device = create_trmnl_device!
    device.update!(cached_image: "existingbase64", cached_image_at: Time.current)

    get "/api/display", headers: {"ID" => device.mac_address, "ACCESS_TOKEN" => device.api_key}

    assert_response :success
  end

  # --- /api/log ---

  test "log returns 204 with valid credentials" do
    device = create_trmnl_device!

    post "/api/log",
      params: {logs: [{message: "test"}]}.to_json,
      headers: {
        "ID" => device.mac_address,
        "ACCESS_TOKEN" => device.api_key,
        "Content-Type" => "application/json"
      }

    assert_response :no_content
  end

  test "log returns 204 with empty access token" do
    device = create_trmnl_device!

    post "/api/log",
      params: {logs: [{message: "test"}]}.to_json,
      headers: {
        "ID" => device.mac_address,
        "ACCESS_TOKEN" => "",
        "Content-Type" => "application/json"
      }

    assert_response :no_content
  end

  test "log returns 401 with invalid credentials" do
    device = create_trmnl_device!

    post "/api/log",
      params: {logs: [{message: "test"}]}.to_json,
      headers: {
        "ID" => device.mac_address,
        "ACCESS_TOKEN" => "wrong",
        "Content-Type" => "application/json"
      }

    assert_response :unauthorized
  end

  private

  def create_trmnl_device!(mac: "11:22:33:44:55:66")
    Device.create!(
      name: "Test TRMNL #{mac}",
      model: "trmnl_og",
      mac_address: mac
    )
  end
end

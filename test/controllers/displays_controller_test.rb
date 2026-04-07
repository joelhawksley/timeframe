# frozen_string_literal: true

require "test_helper"

class DisplaysControllerTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.delete(DEPLOY_TIME.to_s + HomeAssistantApi::WEATHER_DOMAIN)
    @account = test_user.accounts.first
    @location = @account.locations.first
    @mira = Device.find_or_create_by!(name: "test-mira", model: "boox_mira_pro") do |d|
      d.location = @location
    end
    @thirteen = Device.find_or_create_by!(name: "test-thirteen", model: "visionect_13") do |d|
      d.location = @location
    end
    @mira.update!(demo_mode_enabled: false, confirmed_at: Time.current, confirmation_code: nil)
    @thirteen.update!(demo_mode_enabled: false, confirmed_at: Time.current, confirmation_code: nil)
  end

  test "should get mira display with no data" do
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@mira.id}"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should get thirteen display with no data" do
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@thirteen.id}"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should handle errors in thirteen display" do
    DisplayContent.stub :new, -> {
      obj = Object.new
      def obj.call(*)
        raise StandardError.new("Test error message")
      end
      obj
    } do
      get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@thirteen.id}"

      assert_response :success
      assert_includes response.body, "StandardError"
      assert_includes response.body, "Test error message"
    end
  end

  test "should handle errors in mira display" do
    DisplayContent.stub :new, -> {
      obj = Object.new
      def obj.call(*)
        raise StandardError.new("Test error message")
      end
      obj
    } do
      get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@mira.id}"

      assert_response :success
      assert_includes response.body, "StandardError"
      assert_includes response.body, "Test error message"
    end
  end

  test "returns 404 for unknown device" do
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/nonexistent"
    assert_response :not_found
  end

  test "should get mira display in demo mode" do
    @mira.update!(demo_mode_enabled: true)
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@mira.id}"

    assert_response :success
    assert_includes response.body, "Spotted Towhee"
    assert_includes response.body, "Tycho"
    assert_includes response.body, "Tomorrow"
  end

  test "should get thirteen display in demo mode" do
    @thirteen.update!(demo_mode_enabled: true)
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@thirteen.id}"

    assert_response :success
    assert_includes response.body, "Spotted Towhee"
    assert_includes response.body, "Tomorrow"
  end

  test "screenshot returns image for device with cached image" do
    @thirteen.update!(cached_image: Base64.strict_encode64("fake png data"), cached_image_at: Time.current)
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@thirteen.id}/screenshot"
    assert_response :success
    assert_equal "image/png", response.media_type
  end

  test "screenshot refreshes and returns image when no cache" do
    @thirteen.update!(cached_image: nil, cached_image_at: nil)
    fake_b64 = Base64.strict_encode64("fake png data")

    ScreenshotService.stub :capture, fake_b64 do
      get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@thirteen.id}/screenshot"
      assert_response :success
      assert_equal "image/png", response.media_type
    end
  end

  test "screenshot returns 404 for unknown device" do
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/nonexistent/screenshot"
    assert_response :not_found
  end

  test "mira display sets refresh parameter" do
    get "/accounts/#{@account.id}/locations/#{@location.id}/displays/#{@mira.id}?refresh=false"
    assert_response :success
  end
end

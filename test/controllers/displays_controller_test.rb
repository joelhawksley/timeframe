# frozen_string_literal: true

require "test_helper"

class DisplaysControllerTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.delete(DEPLOY_TIME.to_s + HomeAssistantApi::WEATHER_DOMAIN)
    @mira = Device.find_or_create_by!(name: "test-mira", model: "boox_mira_pro")
    @thirteen = Device.find_or_create_by!(name: "test-thirteen", model: "visionect_13")
  end

  test "should get mira display with no data" do
    get "/accounts/me/displays/#{@mira.name}"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should get thirteen display with no data" do
    get "/accounts/me/displays/#{@thirteen.name}"

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
      get "/accounts/me/displays/#{@thirteen.name}"

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
      get "/accounts/me/displays/#{@mira.name}"

      assert_response :success
      assert_includes response.body, "StandardError"
      assert_includes response.body, "Test error message"
    end
  end

  test "returns 404 for unknown device" do
    get "/accounts/me/displays/nonexistent"
    assert_response :not_found
  end
end

# frozen_string_literal: true

require "test_helper"

class DisplaysControllerTest < ActionDispatch::IntegrationTest
  def setup
    Rails.cache.delete(DEPLOY_TIME.to_s + "home_assistant_weather_api")
  end

  test "should get #mira with no data" do
    get "/mira"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should get #thirteen with no data" do
    get "/thirteen"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should handle errors in #thirteen" do
    DisplayContent.stub :new, -> {
      obj = Object.new
      def obj.call(*)
        raise StandardError.new("Test error message")
      end
      obj
    } do
      get "/thirteen"

      assert_response :success
      assert_includes response.body, "StandardError"
      assert_includes response.body, "Test error message"
    end
  end

  test "should handle errors in #mira" do
    DisplayContent.stub :new, -> {
      obj = Object.new
      def obj.call(*)
        raise StandardError.new("Test error message")
      end
      obj
    } do
      get "/mira"

      assert_response :success
      assert_includes response.body, "StandardError"
      assert_includes response.body, "Test error message"
    end
  end
end

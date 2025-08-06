# frozen_string_literal: true

require "test_helper"

class DisplaysControllerTest < ActionDispatch::IntegrationTest
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

  test "should run demo mode" do
    mock_api = HomeAssistantApi.new
    def mock_api.demo_mode?
      true
    end

    HomeAssistantApi.stub :new, mock_api do
      get "/mira"

      assert_response :success
      assert_includes response.body, "Smart Home Solver demo"
    end
  end
end

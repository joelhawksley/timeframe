# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get #mira with no data" do
    VCR.use_cassette("sonos_fetch", match_requests_on: [:method]) do
      get "/mira"

      # look for tomorrow's day name, as current day is not always shown
      assert_includes response.body, "Tomorrow"

      assert_response :success
    end
  end

  test "should get #thirteen with no data" do
    get "/thirteen"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, "Tomorrow"

    assert_response :success
  end

  test "should get #logs with no data" do
    get "/logs"

    assert_response :success
  end

  test "should get #redirect with no data" do
    get "/redirect"

    assert_response 302
  end
end

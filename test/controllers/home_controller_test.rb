# frozen_string_literal: true

require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get #mira with no data" do
    get "/mira"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, Date.tomorrow.strftime("%A")

    assert_response :success
  end

  test "should get #thirteen with no data" do
    get "/thirteen"

    # look for tomorrow's day name, as current day is not always shown
    assert_includes response.body, Date.tomorrow.strftime("%A")

    assert_response :success
  end

  test "should get #logs with no data" do
    get "/logs"

    assert_response :success
  end

  test "should get #weather_data with no data" do
    get "/weather_data"

    assert_response :success
  end

  test "should get #calendar_data with no data" do
    get "/calendar_data"

    assert_response :success
  end
end
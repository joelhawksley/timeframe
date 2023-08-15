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
end
# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "privacy page is publicly accessible" do
    get "/privacy"
    assert_response :success
    assert_includes response.body, "Privacy Policy"
  end

  test "terms page is publicly accessible" do
    get "/terms"
    assert_response :success
    assert_includes response.body, "Terms of Service"
  end
end

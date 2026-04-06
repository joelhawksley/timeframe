# frozen_string_literal: true

require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "privacy page returns not found in single-tenant mode" do
    get "/privacy"
    assert_response :not_found
  end

  test "terms page returns not found in single-tenant mode" do
    get "/terms"
    assert_response :not_found
  end
end

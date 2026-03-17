# frozen_string_literal: true

require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "status page shows display links and api status" do
    get "/status_page"

    assert_response :success
    assert_includes response.body, "Timeframe"
    assert_includes response.body, "Devices"
    assert_includes response.body, "States"
    assert_includes response.body, "Unhealthy"
  end

  test "status returns json health info" do
    get "/status"

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("apis")
    assert json["apis"].is_a?(Array)

    api_names = json["apis"].map { it["name"] }
    assert_includes api_names, "States"
    assert_includes api_names, "Weather"

    json["apis"].each do |api|
      assert api.key?("healthy")
      assert api.key?("last_fetched_at")
    end
  end
end

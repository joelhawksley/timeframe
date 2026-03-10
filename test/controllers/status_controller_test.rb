# frozen_string_literal: true

require "test_helper"

class StatusControllerTest < ActionDispatch::IntegrationTest
  test "root shows display links and api status" do
    get "/"

    assert_response :success
    assert_includes response.body, "Timeframe"
    assert_includes response.body, "/mira"
    assert_includes response.body, "/thirteen"
    assert_includes response.body, "HomeAssistantApi"
    assert_includes response.body, "Unhealthy"
  end

  test "status returns json health info" do
    get "/status"

    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("apis")
    assert json["apis"].is_a?(Array)

    api_names = json["apis"].map { it["name"] }
    assert_includes api_names, "HomeAssistantApi"
    assert_includes api_names, "HomeAssistantWeatherApi"
    assert_includes api_names, "WeatherKitApi"

    json["apis"].each do |api|
      assert api.key?("healthy")
      assert api.key?("last_fetched_at")
    end
  end
end
